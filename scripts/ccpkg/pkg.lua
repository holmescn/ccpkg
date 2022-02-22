---@diagnostic disable: undefined-field
local Pkg = {}
local function search(t, key)
  local mt = getmetatable(t)
  if t.data[key] then return t.data[key] end
  local version_info = t.versions[t.version]
  if version_info and version_info[key] then
    return version_info[key]
  end
  if mt[key] then return mt[key] end
  if t.project[key] then return t.project[key] end
end
Pkg.__index = search

function Pkg:new(o)
  o.data = {version='', env={}}
  o.data.env['PATH'] = os.getenv("PATH"):split(os.pathsep)
  o.project = {}
  setmetatable(o, self)
  return o
end

function Pkg:init(arch, desc)
  self.data.arch = arch
  if type(desc) == "string" then
    self.data.version = desc
  elseif type(desc) == "table" then
    for k, v in pairs(desc) do
      self.data[k] = v
    end
  end

  if self.version == 'latest' then
    local version = self.versions[self.version]
    self.version = version
  end

  if not self.versions[self.version] then
    error(("%s do not have version '%s'"):format(self.name, self.version))
  end

  if type(self.buildsystem) == "string" then
    self.buildsystem = require('buildsystem.' .. self.buildsystem):init(self)
  end

  return self
end

function Pkg:is_installed()
  local package_file = os.path.join(self.dirs.packages, ("%s-%s.lua"):format(self.name, self.version))
  if not os.path.exists(package_file) then return false end
  local package_data = dofile(package_file)
  if not package_data[self.arch] then return false end

  for f in table.iterate(package_data.files) do
    local full_path = os.path.join(self.dirs.installed, self.arch .. "-" .. self.platform.name, f)
    if not os.path.exists(full_path) then return false end
  end

  return true
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

  self.data.build_dir = os.path.join(self.build_base_dir, self.arch .. '-' .. self.platform.name)
  if os.path.exists(self.build_dir) then
    os.rmdirs(self.build_dir)
  end
  os.mkdirs(self.build_dir)

  self.data.install_dir = os.path.join(self.dirs.installed,
    self.arch .. "-" .. self.platform.name)
end

function Pkg:patch_source()
  -- placeholder
end

function Pkg:dependencies()
  -- placeholder
  return {}
end

function Pkg:before_build_steps()
  -- placeholder
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
  -- placeholder
end

function Pkg:save_package(files)
  local file_set = {}
  for v in table.iterate(files) do
    file_set[v] = 1
  end

  files = {}
  for v in table.iterate(os.path.snapshot(self.install_dir)) do
    if not file_set[v] then
      table.insert(files, v)
    end
  end
  table.sort(files)

  local package_data = {}
  local package_file = os.path.join(self.dirs.packages, ("%s-%s.lua"):format(self.name, self.version))
  if os.path.exists(package_file) then
    package_data = dofile(package_file)
  end

  package_data.files = files
  package_data[self.arch] = "installed"

  local file_handle = io.open(package_file, 'w+')
  file_handle:write("return " .. table.dump(package_data))
  file_handle:close()
end

return Pkg