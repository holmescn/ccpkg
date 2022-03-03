---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
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
  self.data.tuplet = opt.tuplet or ''
  self.data.machine = opt.machine or ''
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

  self.data.full_name = self.name .. '-' .. self.version
  return self
end

function Pkg:is_installed()
  local package_file = os.path.join(self.dirs.packages, self.full_name .. '.lua')
  if not os.path.exists(package_file) then
    return false
  end

  local package_data = dofile(package_file)
  local installed = true
  for f in table.each(package_data.files) do
    local full_path = os.path.join(self.dirs.installed, self.tuplet, f)
    if not os.path.exists(full_path) then
      installed = false
      break
    end
  end

  if not installed then
    for f in table.each(package_data.files) do
      local full_path = os.path.join(self.dirs.installed, f)
      if os.path.exists(full_path) then
        os.remove(full_path)
        print("--- remove " .. full_path)
      end
    end
  end

  return installed
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

  local src_dir = os.path.join(tmp_dir, self.full_name .. '-src')
  if os.path.exists(src_dir) then
    os.rmdirs(src_dir)
  end

  local dirs_filter = {}
  for root, dirs, _ in os.walk(tmp_dir) do
    for d in table.each(dirs) do
      dirs_filter[os.path.join(root, d)] = true
    end
    break
  end

  if is_tarball then
    os.run("tar xf " .. self.downloaded, {cwd=tmp_dir, check=1})
  elseif is_zip then
    -- os.run("unzip x" .. self.downloaded, {cwd=tmp_dir, check=true})
    error("handle zip file please")
  end

  for root, dirs, _ in os.walk(tmp_dir) do
    for d in table.each(dirs) do
      local dir = os.path.join(root, d)
      if not dirs_filter[dir] then
        os.rename(dir, src_dir)
        break
      end
    end
    break
  end

  self.data.src_dir = src_dir
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

  self.data.install_dir = os.path.join(self.dirs.installed, self.tuplet)
  self.data.package_file = os.path.join(self.dirs.packages, self.full_name .. '.lua')
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
  self.data.files = os.path.files(self.install_dir)
end

function Pkg:execute(step, opt)
  if self[step] then
    self[step](self, opt)
  else
    self.buildsystem[step](self.buildsystem, self, opt)
  end
end

function Pkg:execute_hook(prefix, step, opt)
  local name = prefix .. "_" .. step
  if self[name] then
    self[name](self, opt)
  end
end

function Pkg:after_build_steps()
  self:save_package()
  self:fix_pkgconfig()
end

function Pkg:save_package()
  local package_data = {
    name=self.name,
    version=self.version
  }
  if os.path.exists(self.package_file) then
    package_data = dofile(self.package_file)
  end

  local exists_checker = table.create_filter(self.files)

  local added_files = {}
  for f in table.each(os.path.files(self.install_dir)) do
    if not exists_checker[f] then
      table.insert(added_files, f)
    end
  end

  if package_data.files then
    exists_checker = table.create_filter(package_data.files)
    for f in table.each(added_files) do
      if not exists_checker[f] then
        if not package_data[self.tuplet] then
          package_data[self.tuplet] = {}
        end
        table.insert(package_data[self.tuplet], f)  
      end
    end
    if package_data[self.tuplet] then
      table.sort(package_data[self.tuplet])
    end
  else
    package_data.files = added_files
    table.sort(package_data.files)
  end
  self.data.files = added_files

  local package_file = io.open(self.package_file, "w+")
  package_file:write('return ' .. table.serialize(package_data))
  package_file:close()
end

function Pkg:fix_pkgconfig()
  local pkgconfig_file = nil
  for f in table.each(self.files) do
    local filename = os.path.basename(f)
    if filename:match("%.pc$") then
      pkgconfig_file = os.path.join(self.install_dir, f)
      break
    end
  end
  if not pkgconfig_file then return end

  print('--- fix pkgconfig: ' .. os.path.join('.', os.path.relpath(pkgconfig_file, self.project_dir)))

  ccpkg.edit(pkgconfig_file, function(line)
    local var_name, value = line:match('^([%w_]+)%s*=%s*(.*)$')
    if var_name then
      if var_name == 'prefix' then
        value = ''
      elseif var_name == 'exec_prefix' then
        value = '${prefix}'
      elseif var_name == 'includedir' then
        value = os.path.join('${prefix}', 'include')
      elseif var_name == 'libdir' then
        value = os.path.join('${prefix}', 'lib')
      end
      return ("%s=%s"):format(var_name, value)
    else
      return line
    end
  end)
end

return Pkg