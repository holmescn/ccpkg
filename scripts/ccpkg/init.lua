local ccpkg = {
  root_dir=os.getenv("CCPKG_ROOT"),
  scripts_dir=os.path.join(os.getenv("CCPKG_ROOT"), "scripts"),
  mt={}
}
setmetatable(ccpkg, ccpkg.mt)

ccpkg.mt.__index = function (t, k)
  local s = os.path.join(ccpkg.scripts_dir, "ccpkg", k .. ".lua")
  if os.path.exists(s) then
    return require ("ccpkg." .. k)
  end
  s = os.path.join(ccpkg.scripts_dir, "buildsystem", k .. ".lua")
  if os.path.exists(s) then
    return require ("buildsystem." .. k)
  end
end

function ccpkg:create_opt(pkg, desc, arch)
  local o = {pkg=pkg}
  o.version = desc.version
  o.versioned_name = pkg.name .. '-' .. desc.version
  o.platform = self.project.target.platform
  o.arch = arch
  o.arch_platform = arch .. "_" .. o.platform
  o.src_dir = pkg.src_dir
  return o
end

function ccpkg:load_project(filename)
  local project_file = os.path.join {os.curdir(), filename}
  print("project file", project_file)
  assert(os.path.exists(project_file), project_file .. " not exists")
  return dofile(project_file)
end

function ccpkg:create_dirs(dirs)
  local working_dir = os.path.join {os.curdir(), '.ccpkg'}
  if not os.path.exists(working_dir) then
     os.mkdirs(working_dir)
  end

  local ret_dirs = {working_dir=working_dir}
  for _, subdir in ipairs(dirs) do
     local dir_path = os.path.join {working_dir, subdir}
     if subdir == "tmp" then
        os.rmdirs(dir_path)
     end
     if not os.path.exists(dir_path) then
        os.mkdirs(dir_path)
     end
     ret_dirs[subdir] = dir_path
  end
  return ret_dirs
end

function ccpkg:cmd_exists(cmd_name)
  local cmd = ("which %s > /dev/null"):format(cmd_name)
  local exists = os.execute(cmd)
  return exists
end

function ccpkg:cmd_full_path(cmd_name)
  local cmd = ("which %s"):format(cmd_name)
  local h = io.popen(cmd, "r")
  local r = h:read("*all"):trim()
  h:close()
  return r
end

function ccpkg:common_paths()
  local home = os.getenv("HOME")
  return {
    "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin",
    os.path.join {home, ".local", "bin"}
  }
end

function ccpkg:check_version(pkg, version)
  local v = pkg.versions[version]
  assert(v, ("unknown version '%s' of %s"):format(version, pkg.name))
  pkg.version = {}
  for key, val in pairs(v) do
    pkg.version[key] = val
  end
end

function ccpkg:check_downloaded(pkg)
  pkg.version.downloaded = pkg.version.downloaded or {}

  local filename = pkg.version.filename
  if not filename then
    if pkg.version.url then
      filename = pkg.version.url:match("/([^/]+)$")
    end
  end
  assert(filename, "invalid filename")
  pkg.version.downloaded.filename = filename

  pkg.version.downloaded.full_path = os.path.join(self.dirs.downloads, filename)

  if os.path.exists(pkg.version.downloaded.full_path) then
    if self:checksum(pkg) then
      return true
    end
    os.remove(pkg.version.downloaded.full_path)
  end
  return false
end

function ccpkg:check_installed(opt)
  local dir = opt.versioned_name .. '-' .. opt.arch_platform
  return os.path.exists(os.path.join(self.dirs.installed, dir))
end

function ccpkg:transform_envs(envs)
  local envs_lst = {}
  for k, v in pairs(envs) do
    if type(v) == "string" then
      table.insert(envs_lst, k .. "=" .. v)
    elseif type(v) == "table" then
      table.insert(envs_lst, k .. "=" .. table.concat(v, ":"))
    else
      table.insert(envs_lst, k .. "=" .. tostring(v))
    end
  end
  return envs_lst
end

function ccpkg:log_filename(opt, step, config)
  local filename = ("%s-%s-%s-%s.log"):format(step, opt.arch, opt.platform, config)
  return os.path.join {opt.build_dir, "..", filename}
end

return ccpkg