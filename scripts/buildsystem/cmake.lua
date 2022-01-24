local ccpkg = require "ccpkg"
local CMake = {
  envs={
    PATH=ccpkg:common_paths()
  },
  configs={
    rel="Release",
    dbg="Debug"
  }
}

function CMake:detect()
  if self.cmake then return end

  self.cmake = ccpkg:cmd_full_path("cmake")
  assert(self.cmake ~= "", "no cmake found in current $PATH")
  local cmake_path = self.cmake:gsub("(.*)/[^/]*$", "%1")
  if not table.contains(self.envs["PATH"], cmake_path) then
    table.insert(self.envs["PATH"], cmake_path)
  end

  if ccpkg:cmd_exists('ninja') then
    self.ninja = ccpkg:cmd_full_path("ninja")
    local ninja_path = self.ninja:gsub("(.*)/[^/]*$", "%1")
    if not table.contains(self.envs["PATH"], ninja_path) then
      table.insert(self.envs["PATH"], ninja_path)
    end
  end
end

function CMake:construct_configure_args(opt)
  local args = {}
  if type(opt.args) == "table" then
    args = table.merge(args, opt.args)
  end
  for k, v in pairs(opt.options) do
    if type(v) == "boolean" then
      if v then
        table.insert(args, "-D" .. k .. "=ON")
      else
        table.insert(args, "-D" .. k .. "=OFF")
      end
    elseif type(v) == "string" then
      table.insert(args, "-D" .. k .. "=" .. v)
    else
      table.insert(args, "-D" .. k .. "=" .. tostring(v))
    end
  end
  return args
end

function CMake:configure(opt, config)
  local build_dir = opt.src_dir:gsub("-src$", "-build")
  build_dir = os.path.join {build_dir, ("%s-%s-%s"):format(opt.arch, opt.platform, config)}
  os.mkdirs(build_dir)
  opt.build_dir = build_dir

  local args = self:construct_configure_args(opt)
  table.insert(args, 1, self.cmake)
  if self.ninja then
    table.insert(args, "-GNinja")
  end
  table.insert(args, opt.src_dir)
  local cmd = {cmd=self.cmake, args=args, envs=opt.envs}
  cmd.out = ccpkg:log_filename(opt, "config", config)

  os.chdir(build_dir)

  print(">>> Configuring")
  assert(os.run(cmd) == 0, "cmake configure failed")
end

function CMake:build(opt, config)
  local cmd = {cmd=self.cmake, envs=opt.envs}
  cmd.out = ccpkg:log_filename(opt, "build", config)
  cmd.args = {self.cmake, "--build", opt.build_dir, "--config", self.configs[config]}
  print(">>> Building")
  assert(os.run(cmd) == 0, "cmake build failed")
end

function CMake:install(opt, config)
  local install_dir = os.path.join(ccpkg.dirs.installed, opt.versioned_name .. '-' .. opt.arch_platform)
  if config == 'dbg' then
    install_dir = os.path.join {install_dir, "debug"}
  end

  if os.path.exists(install_dir) then
    os.rmdirs(install_dir)
  end
  os.mkdirs(install_dir)

  opt.install_dir = opt.install_dir or {}
  opt.install_dir[config] = install_dir

  local cmd = {cmd=self.cmake, envs=opt.envs}
  cmd.out = ccpkg:log_filename(opt, "install", config)
  cmd.args = {
    self.cmake,
    "--install", ".",
    "--prefix", install_dir,
    "--config", self.configs[config]
  }

  print(">>> Installing to", install_dir)
  if os.run(cmd) ~= 0 then
    os.rmdirs(install_dir)
    error(">>> Install Failed")
  end
end

function ccpkg:cmake(opt)
  CMake:detect()

  opt.args = {}
  opt.options = {}
  if opt.pkg.before_configuration then
    opt.pkg:before_configuration(ccpkg, opt)
  end

  -- append platform specific args and envs
  local platform = require("platform." .. opt.platform)
  platform:cmake(opt)

  opt.envs = ccpkg:transform_envs(CMake.envs)

  local pwd = os.curdir()
  for _, c in ipairs({"rel", "dbg"}) do
    print((">>> Build for %s-%s-%s"):format(opt.arch, opt.platform, c))
    CMake:configure(opt, c)
    CMake:build(opt, c)
    CMake:install(opt, c)
    print((">>> %s %s-%s-%s installed"):format(opt.versioned_name, opt.arch, opt.platform, c))  
  end
  os.chdir(pwd)

  os.move(os.path.join(opt.install_dir.dbg, "lib"),
          os.path.join(opt.install_dir.rel, "lib", "debug"))
end

return ccpkg.cmake