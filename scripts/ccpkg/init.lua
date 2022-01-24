ccpkg = {
  root_dir=os.getenv("CCPKG_ROOT"),
  scripts_dir=os.path.join(os.getenv("CCPKG_ROOT"), "scripts")
}

local function search(t, k)
  local fn = os.path.join(ccpkg.scripts_dir, "ccpkg", k .. ".lua")
  if os.path.exists(fn) then
    return dofile(fn)
  end
end

setmetatable(ccpkg, {__index=search})

function ccpkg:create_opt(pkg, desc)
  local o = {pkg=pkg, envs}
  local version = pkg.versions[desc.version]
  for k, v in pairs(version) do
    o[k] = v
  end
  o.version = desc.version
  o.name_version = ("%s-%s"):format(pkg.name, desc.version)
  o.platform = self.project.target.platform
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
end

function ccpkg:downloaded(opt)
  print(table)
  local filename = opt.downloaded_filename
  if not filename then
    if opt.url then
      filename = opt.url:match("/([^/]+)$")
    end
  end
  assert(filename, "invalid filename")
  opt.downloaded_filename = filename

  opt.downloaded_file_path = os.path.join(self.dirs.downloads, filename)
  if os.path.exists(opt.downloaded_file_path) then
    if self:checksum(opt) then
      return true
    end
    os.remove(full_path)
  end
  return false
end

function ccpkg:installed(pkg, opt)
  return false
end

dofile( os.path.join(ccpkg.scripts_dir, "ext", "init.lua") )
dofile( os.path.join(ccpkg.scripts_dir, "cli", "init.lua") )