local Tools = require "tools"
local CMake = {}

function CMake:detect(paths)
  assert(ccpkg:cmd_exists("cmake"), "no cmake found in current $PATH")
  self.cmake = ccpkg:cmd_full_path("cmake")
  local cmake_path = self.cmake:gsub("(.*)/[^/]*$", "%1")
  if not table.contains(paths, cmake_path) then
    table.insert(paths, cmake_path)
  end

  if ccpkg:cmd_exists('ninja') then
    self.ninja = ccpkg:cmd_full_path("ninja")
    local ninja_path = self.ninja:gsub("(.*)/[^/]*$", "%1")
    if not table.contains(paths, ninja_path) then
      table.insert(paths, ninja_path)
    end
  end
end

function CMake:paths_to_envs(envs, paths)
  local sep = ":"
  local env_path = envs['PATH'] or ""
  env_path = env_path:split(sep)
  for _, p in ipairs(paths) do
    table.insert(env_path, p)
  end
  envs["PATH"] = table.concat(env_path, sep)
end

function CMake:configure(pkg, options, cfg)
  local build_dir = pkg.src_dir:gsub("-src$", "-build")
  build_dir = path.join {build_dir, options.arch .. '_' .. ccpkg.target.platform, cfg:lower()}
  if fs.exists(build_dir) then
    os.remove(build_dir)
  end
  fs.mkdirs(build_dir)
  pkg.data.build_dir = build_dir

  local args = table.clone(options.args)
  table.insert(args, 1, self.cmake)
  table.insert(args, "-B")
  table.insert(args, pkg.build_dir)
  if self.ninja then
    table.insert(args, "-GNinja")
  end
  table.insert(args, pkg.src_dir)
  options.cmd.args = args
  options.cmd.out = path.join {pkg.build_dir, "config.log"}

  print(">>> Configuration Step", cfg)
  assert(os.run(options.cmd) == 0, "cmake configure failed")
  print(">>> Configuration Step", "Success")
end

function CMake:build(pkg, options, cfg)
  options.cmd.out = path.join {pkg.build_dir, "build.log"}
  options.cmd.args = {self.cmake, "--build", pkg.build_dir, "--config", cfg}
  print(">>> Build Step    ", cfg)
  assert(os.run(options.cmd) == 0, "cmake build failed")
  print(">>> Build Step    ", "Success")
end

function CMake:install(pkg, options, cfg)
  local install_dir = ("%s-%s-%s_%s"):format(pkg.name, pkg.version, options.arch, ccpkg.target.platform)
  if cfg == 'Debug' then
    install_dir = path.join {ccpkg.dirs.installed, install_dir, "debug"}
  else
    install_dir = path.join {ccpkg.dirs.installed, install_dir}
  end
  if fs.exists(install_dir) then
    os.remove(install_dir)
  end
  fs.mkdirs(install_dir)

  options.cmd.out = path.join {pkg.build_dir, "install.log"}
  options.cmd.args = {
    self.cmake,
    "--install", pkg.build_dir,
    "--prefix", install_dir,
    "--config", cfg
  }

  print(">>> Install Step", cfg)
  assert(os.run(options.cmd) == 0, "cmake install failed")
  print(">>> Install Step", "Success")
end

function Tools:cmake(pkg, options)
  options.cmd = {cmd='', args={}, envs={}, out=''}
  options.paths = ccpkg:common_paths()
  options.args = options.args or {}
  options.envs = options.envs or {}
  CMake:detect(options.paths)

  if type(options.options) == "table" then
    for _, v in ipairs(options.options) do
      table.insert(options.args, "-D" .. v)
    end
  end

  ccpkg.platform:cmake(pkg, options)
  CMake:paths_to_envs(options.envs, options.paths)
  options.cmd.envs = table.toarray(options.envs)
  options.cmd.cmd = CMake.cmake

  for _, cfg in ipairs({"Debug", "Release"}) do
    CMake:configure(pkg, options, cfg)
    CMake:build(pkg, options, cfg)
    CMake:install(pkg, options, cfg)
    print((">>> %s %s %s on %s_%s installed"):format(pkg.name, pkg.version, cfg:lower(), options.arch, ccpkg.target.platform))
  end
end