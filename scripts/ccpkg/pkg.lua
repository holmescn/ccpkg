local Pkg = {}
local function search(t, key)
  local mt = getmetatable(t)
  if t.data[key] then return t.data[key] end
  local version_info = t.versions[t.version]
  if version_info and version_info[key] then
    return version_info[key]
  end
  if t.project[key] then return t.project[key] end
  if mt[key] then return mt[key] end
end
Pkg.__index = search

function Pkg:new(o)
  o = o or {}
  o.data = {envs={}, version=''}
  o.data.envs['PATH'] = os.getenv("PATH"):split(os.pathsep)
  o.project = {}
  o.platform = {}
  o.dependencies = o.dependencies or {}
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
  return false
end

function Pkg:download_source()
  require("ccpkg.download"):execute(self)
end

function Pkg:unpack_source()
  local tmp_dir = pkg.dirs.tmp
  local filename = os.path.basename(pkg.downloaded)
  local name, ext = filename:match("^(.*)%.([^.]+)$")
  local is_tarball = false
  local is_zip = false
  if name:match("%.tar$") then
    name = name:match("^(.+)%.tar$")
    is_tarball = true
  elseif ext == "zip" then
    is_zip = true
  else
    error("unknown file type of " .. filename)
  end
end

function Pkg:patch_source()
  -- placeholder
  print("patch source")
end

function Pkg:before_build_steps()
  -- placeholder
  print("before build steps")
end

function Pkg:execute(step)
  if self[step] then
    print("execute", step)
    self[step](self, step)
  end
end

function Pkg:after_build_steps()
  -- placeholder
  print("after build steps")
end

function Pkg:save_package(files)
  print("save package")
end

return Pkg