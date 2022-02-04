local ccpkg = {
  root_dir=os.getenv("CCPKG_ROOT"),
  ports_dir=os.path.join(os.getenv("CCPKG_ROOT"), "ports"),
  scripts_dir=os.path.join(os.getenv("CCPKG_ROOT"), "scripts"),
  mt={}
}
setmetatable(ccpkg, ccpkg.mt)

ccpkg.mt.__index = function (t, k)
  local s = os.path.join(ccpkg.scripts_dir, "ccpkg", k .. ".lua")
  if os.path.exists(s) then
    return require ("ccpkg." .. k)
  end
end

function ccpkg:load_project(filename)
  self.project_file = os.path.join {os.curdir(), filename}
  assert(os.path.exists(self.project_file), self.project_file .. " not exists")
  return dofile(self.project_file)
end

function ccpkg:create_dirs()
  local dirs = {}
  dirs.working_dir = os.path.join {os.curdir(), '.ccpkg'}
  if not os.path.exists(dirs.working_dir) then
     os.mkdirs(dirs.working_dir)
  end

  dirs.tmp = os.path.join(dirs.working_dir, 'tmp')
  dirs.downloads = os.path.join(dirs.working_dir, 'downloads')
  dirs.installed = os.path.join(dirs.working_dir, 'installed')

  if os.path.exists(dirs.tmp) then
    os.rmdirs(dirs.tmp)
  end

  for _, dir in pairs(dirs) do
    os.mkdirs(dir)
  end

  return dirs
end

local function pkg_cmp(a, b)
  local split_pattern = "^(.*):(.*)$"
  local a_name, a_version = a:match(split_pattern)
  local b_name, b_version = b:match(split_pattern)
  if a_name == b_name then
    local pkg = ccpkg:require_pkg(a_name)
    if pkg['version_cmp'] then
      return pkg.version_cmp(a_version, b_version)
    else
      return a_version < b_version
    end
  else
    -- local pkg_a = ccpkg:require_pkg(a_name)
    -- local pkg_b = ccpkg:require_pkg(b_name)
    return a_name < b_name
  end
end

function ccpkg:create_pkg_list()
  local pkg_list = {}
  local loaded_pkg = {}
  for pkg_name, r in pairs(self.project.dependencies) do
    local pkg = self:require_pkg(pkg_name)
    local version = self:check_pkg_version(pkg, r)
    if loaded_pkg[pkg_name] then
      if version ~= loaded_pkg[pkg_name] then
        error(("%s version conflict: %s <-> %s"):format(pkg_name, version, loaded_pkg[pkg_name]))
      end
    else
      loaded_pkg[pkg_name] = version
      table.insert(pkg_list, pkg_name .. ":" .. version)
    end
  end
  table.sort(pkg_list, pkg_cmp)
  return pkg_list
end

function ccpkg:require_pkg(pkg_name)
  local status, pkg = pcall(require, "ports." .. pkg_name)
  if not status then
    error(pkg_name .. " not found in " .. self.ports_dir)
  end
  return pkg
end

function ccpkg:check_pkg_version(pkg, requirement)
  local version = ''
  if type(requirement) == "string" then
    version = requirement
  elseif type(requirement) == "table" then
    version = requirement.version
  else
    error("invalid pkg requirement")
  end

  local version_info = pkg.versions[version]
  if not version then
    error(pkg.name .. " do not have version " .. version)
  end

  -- process 'latest' version
  if type(version_info) == "string" then
    version = version_info
    version_info = pkg.versions[version]
  end

  return version
end

function ccpkg:create_opt(pkg, arch)
  local o = {pkg=pkg}
  o.version = pkg.current.version
  o.versioned_name = pkg.name .. '-' .. o.version
  o.platform = self.project.target.platform
  o.arch = arch
  o.arch_platform = arch .. "_" .. o.platform
  o.target_triplet = arch .. '-' .. o.platform
  o.src_dir = pkg.src_dir
  o.args = {}
  return o
end

function ccpkg:check_downloaded(pkg, version)
  local version_info = pkg.versions[versions]
  pkg.data.downloaded = pkg.data.downloaded or {}

  local filename = ''
  if version_info.filename then
    filename = version_info.filename
  elseif version_info.url then
    filename = version_info.url:match("/(.*)$")
  elseif pkg.filename_pattern then
    filename = pkg.filename_pattern:fmt {version=version}
  elseif pkg.url_pattern then
    local url = pkg.url_pattern:fmt{version=version}
    filename = url:match("/(.*)$")
  end
  assert(filename, "invalid filename")
  pkg.data.downloaded.filename = filename
  pkg.data.downloaded.full_path = os.path.join(self.dirs.downloads, filename)

  if os.path.exists(pkg.data.downloaded.full_path) then
    if self:checksum(pkg, version) then
      return true
    end
    os.remove(pkg.data.downloaded.full_path)
  end
  return false
end

function ccpkg:check_installed(opt)
  local dir = self:install_dir(opt, false)
  return os.path.exists(dir)
end

function ccpkg:transform_envs(envs)
  local new_env = {}
  for k, v in pairs(envs) do
    if type(v) == "string" then
      table.insert(new_env, k .. '=' .. v)
    elseif type(v) == "table" then
      table.insert(new_env, k .. '=' .. table.concat(v, ':'))
    else
      table.insert(new_env, k .. '=' .. tostring(v))
    end
  end
  return new_env
end

function ccpkg:build_dir(opt, suffix)
  local build_dir = opt.src_dir:gsub("-src$", "-build")
  return os.path.join {build_dir, ("%s-%s"):format(opt.target_triplet, suffix)}
end

function ccpkg:install_dir(opt, debug)
  local dir = os.path.join(self.dirs.installed, opt.versioned_name .. '-' .. opt.arch_platform)
  if debug then
    return os.path.join {dir, "debug"}
  end
  return dir
end

function ccpkg:log_filename(opt, step, suffix)
  local filename = ("%s-%s-%s.log"):format(step, opt.target_triplet, suffix)
  return os.path.join {opt.build_dir, "..", filename}
end

function ccpkg:try_call(o, method, ...)
  if o[method] then
    o[method](o, ...)
  end
end

function ccpkg:call_pkg_hook(name, opt)
  self:try_call(opt.pkg, name, self, opt)
end

return ccpkg
