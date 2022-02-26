---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local md5 = require "3rdparty.md5"
local Pkg = {__index=function (t, key)
  if rawget(t, 'data') then
    if t.data[key] then
      -- print('return t.data["' .. key .. '"]')
      return t.data[key]
    end
    if t.data['version'] and t.versions[t.data['version']][key] then
      -- print('return t.versions["' .. t.data['version'] .. '"]["' .. key .. '"]')
      return t.versions[t.version][key]
    end
  end

  local mt = getmetatable(t)
  if mt[key] then
    -- print('return mt["' .. key .. '"]')
    return mt[key]
  end

  if rawget(t, 'data') then
    if t.data['project'] and t.data['project'][key] then
      -- print('return t.project["' .. key .. '"]')
      return t.data.project[key]
    end
  end
  -- print(key .. ' not found')
end}

function Pkg:new(o)
  setmetatable(o, self)
  return o
end

function Pkg:init(opt, spec)
  self.data = {env={}}
  self.data.tuplet = opt.tuplet
  self.data.machine = opt.machine
  self.data.project = opt.project
  self.data.platform = opt.platform
  self.data.patch_path = os.which('patch')
  self.data.env['PATH'] = os.getenv("PATH"):split(os.pathsep)
  self.data.pkg_path = os.path.join(ccpkg.ports_dir, self.name)

  for k, v in pairs(spec) do
    self.data[k] = v
  end

  if spec.version == 'latest' then
    self.data.version = self.versions[spec.version]
  end

  if not self.versions[self.version] then
    error(("%s do not have version '%s'"):format(self.name, self.version))
  end

  if type(self.buildsystem) == "string" then
    self.buildsystem = require('buildsystem.' .. self.buildsystem):init(self)
  end

  self.data.name_version = self.name .. '-' .. self.version
  return self
end

function Pkg:is_installed()
  local install_dir = os.path.join(self.dirs.packages, self.name_version, self.tuplet)
  return os.path.exists(install_dir)
end

function Pkg:download_source()
  require("ccpkg.download"):execute(self)
end

function Pkg:unpack_source()
  local is_zip = false
  local is_tarball = false
  local tmp_dir = self.dirs.tmp
  local filename = os.path.basename(self.downloaded)
  local name, ext = os.path.splitext(filename)
  if name:match("%.tar$") then
    name = os.path.splitext(name)
    is_tarball = true
  elseif ext == ".zip" then
    is_zip = true
  else
    error("unknown file type of " .. filename)
  end

  local dir_1 = os.path.join(tmp_dir, name)
  if os.path.exists(dir_1) then
    os.rmdirs(dir_1)
  end

  local dir_2 = os.path.join(tmp_dir, ("%s-%s-src"):format(self.name, self.version))
  if os.path.exists(dir_2) then
    os.rmdirs(dir_2)
  end

  if is_tarball then
    os.run("tar xf " .. self.downloaded, {cwd=tmp_dir, check=1})
  elseif is_zip then
    -- os.run("unzip x" .. self.downloaded, {cwd=tmp_dir, check=true})
    error("handle zip file please")
  end

  os.rename(dir_1, dir_2)
  self.data.src_dir = dir_2
end

function Pkg:makedirs()
  self.data.build_base_dir = self.src_dir:gsub("-src$", "-build")
  if not os.path.exists(self.build_base_dir) then
    os.mkdirs(self.build_base_dir)
  end

  self.data.build_dir = os.path.join(self.build_base_dir, self.tuplet)
  if os.path.exists(self.build_dir) then
    os.rmdirs(self.build_dir)
  end
  os.mkdirs(self.build_dir)

  self.data.install_dir = os.path.join(self.dirs.packages, self.name_version, self.tuplet)
end

function Pkg:patch_source()
  if not rawget(self, 'patches') then return end

  -- common patches
  for _, patch in ipairs(rawget(self, 'patches')) do
    self:apply_patch(patch)
  end

  -- version related patches
  if self.versions[self.version]['patches'] then
    for _, patch in ipairs(self.versions[self.version]['patches']) do
      self:apply_patch(patch)
    end
  end

  -- platform related patches
  if self.patches[self.platform.name] then
    for _, patch in ipairs(self.patches[self.platform.name]) do
      self:apply_patch(patch)
    end
  end
end

function Pkg:apply_patch(patch)
  local full_path = os.path.join(self.pkg_path, patch)
  print('--- apply ' .. patch)
  os.run({self.patch_path, '-p1', '-i', full_path}, {cwd=self.src_dir, check=true})
end

function Pkg:dependencies()
  -- placeholder
  return {}
end

function Pkg:before_build_steps()
  self:makedirs()
end

function Pkg:execute(step, opt)
  if self[step] then
    self[step](self, step, opt)
  else
    self.buildsystem:execute(step, self, opt)
  end
end

function Pkg:execute_hook(prefix, step, opt)
  local name = prefix .. "_" .. step
  if self[name] then
    self[name](self, opt)
  end
end

function Pkg:after_build_steps()
  self:fix_pkgconfig()
  self:copy_to_sysroot()
end

function Pkg:fix_pkgconfig()
  local pkgconfig = self.name .. '.pc'
  if self.pkgconfig then
    pkgconfig = self.pkgconfig
  end
  pkgconfig = os.path.join(self.install_dir, 'lib', 'pkgconfig', pkgconfig)
  if not os.path.exists(pkgconfig) then return end
  print('--- fix pkgconfig in ' .. pkgconfig)

  local prefix = ''
  ccpkg.edit(pkgconfig, function(line)
    if line:match("^prefix=") then
      prefix = line:match("^prefix=%s*(.*)")
      return 'prefix=/usr'
    elseif line:match("^includedir=") then
      return os.path.join(line:gsub(prefix, '${prefix}'), self.library_arch)
    elseif line:match("^libdir=") then
      return os.path.join(line:gsub(prefix, '${prefix}'), self.library_arch)
    elseif string.len(prefix) > 0 then
      return line:gsub(prefix, '${prefix}')
    else
      return line
    end
  end)
end

function Pkg:copy_to_sysroot()
  local src_lib_dir_root = os.path.join(self.install_dir, 'lib')
  local src_include_dir_root = os.path.join(self.install_dir, 'include')
  local dst_lib_dir_root = os.path.join(self.dirs.sysroot, 'usr', 'lib', self.library_arch)
  local dst_include_dir_root = os.path.join(self.dirs.sysroot, 'usr', 'include', self.library_arch)

  for root, dirs, files in os.walk(self.install_dir) do
    for dir in table.each(dirs) do
      local src_dir = os.path.join(root, dir)
      if src_dir:startswith(src_include_dir_root) then
        local dst_dir = os.path.join(dst_include_dir_root, os.path.relpath(src_dir, src_include_dir_root))
        if not os.path.exists(dst_dir) then
          os.mkdirs(dst_dir)
        end
      elseif src_dir:startswith(src_lib_dir_root) then
        local dst_dir = os.path.join(dst_lib_dir_root, os.path.relpath(src_dir, src_lib_dir_root))
        if not os.path.exists(dst_dir) then
          os.mkdirs(dst_dir)
        end
      end
    end

    for f in table.each(files) do
      local src_file = os.path.join(root, f)
      if src_file:startswith(src_include_dir_root) then
        local dst_file = os.path.join(dst_include_dir_root, os.path.relpath(src_file, src_include_dir_root))
        os.copyfile(src_file, dst_file, {override=1})
      elseif src_file:startswith(src_lib_dir_root) then
        local dst_file = os.path.join(dst_lib_dir_root, os.path.relpath(src_file, src_lib_dir_root))
        os.copyfile(src_file, dst_file, {override=1})
      end
    end
  end
end

function Pkg:hash_file(full_path)
  assert(os.path.exists(full_path), full_path .. " is not found")
  local fp = io.open(full_path, "rb")
  local md5_as_hex = md5.sum_as_hex(fp:read("a"))
  fp:close()
  return md5_as_hex
end

return Pkg