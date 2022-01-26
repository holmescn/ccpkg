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

function ccpkg:cmd_exists(cmd_name)
  local cmd = ("which %s > /dev/null"):format(cmd_name)
  local exists = os.execute(cmd)
  return exists
end

function ccpkg:cmd_paths(cmd_name)
  local handle = io.popen("which " .. cmd_name)
  local result = handle:read("*all"):trim()
  handle:close()

  if result ~= "" then
    local bin_path = result:gsub("(.*)/[^/]*$", "%1")
    return result, bin_path
  end
end

function ccpkg:check_pkg_exists(pkg_name)
  local pkg_path = os.path.join {ccpkg.ports_dir, pkg_name}
  if os.path.exists(pkg_path) then
    local pkg_init_file = os.path.join(pkg_path, "init.lua")
    assert(os.path.exists(pkg_init_file), "no init.lua found in " .. pkg_path)
  else
    local pkg_lua_file = os.path.join(ccpkg.ports_dir, pkg_name .. ".lua")
    assert(os.path.exists(pkg_lua_file), "unknown pkg " .. pkg_name)  
  end
end

function ccpkg:check_version(pkg, version)
  local v = pkg.versions[version]
  assert(v, ("unknown version '%s' of %s"):format(version, pkg.name))
  while type(v) == "string" do
    version = v
    v = pkg.versions[version]
  end
  pkg.current = table.clone(v)
  pkg.current.version = version
end

function ccpkg:check_downloaded(pkg)
  pkg.current.downloaded = pkg.current.downloaded or {}

  local filename = pkg.current.filename
  if not filename then
    if pkg.current.url then
      filename = pkg.current.url:match("/([^/]+)$")
    end
  end
  assert(filename, "invalid filename")
  pkg.current.downloaded.filename = filename

  pkg.current.downloaded.full_path = os.path.join(self.dirs.downloads, filename)

  if os.path.exists(pkg.current.downloaded.full_path) then
    if self:checksum(pkg) then
      return true
    end
    os.remove(pkg.current.downloaded.full_path)
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
