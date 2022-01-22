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
  build_dir = os.path.join {build_dir, options.arch .. '_' .. ccpkg.target.platform, cfg:lower()}
  os.mkdirs(build_dir)
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
  options.cmd.out = os.path.join {pkg.build_dir, "config.log"}

  print(">>> Configuring")
  assert(os.run(options.cmd) == 0, "cmake configure failed")
  print(">>> Configure Success")
end

function CMake:build(pkg, options, cfg)
  options.cmd.out = os.path.join {pkg.build_dir, "build.log"}
  options.cmd.args = {self.cmake, "--build", pkg.build_dir, "--config", cfg}
  print(">>> Building")
  assert(os.run(options.cmd) == 0, "cmake build failed")
  print(">>> Build Success")
end

function CMake:install(pkg, options, cfg)
  local pkg_name = ("%s-%s"):format(pkg.name, pkg.version)
  local target = ("%s_%s"):format(options.arch, ccpkg.target.platform)
  local install_dir = ''
  if cfg == 'Debug' then
    install_dir = os.path.join {ccpkg.dirs.installed, pkg_name, target, "debug"}
  else
    install_dir = os.path.join {ccpkg.dirs.installed, pkg_name, target}
  end

  if os.path.exists(install_dir) then
    os.rmdirs(install_dir)
  end
  os.mkdirs(install_dir)

  if cfg == "Debug" then
    pkg.data.debug_install_dir = install_dir
  else
    pkg.data.release_install_dir = install_dir
  end

  options.cmd.out = os.path.join {pkg.build_dir, "install.log"}
  options.cmd.args = {
    self.cmake,
    "--install", pkg.build_dir,
    "--prefix", install_dir,
    "--config", cfg
  }

  print(">>> Installing")
  assert(os.run(options.cmd) == 0, "cmake install failed")
  print(">>> Install Success")
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

  print((">>> Build for %s-%s %s"):format(options.arch, self.target.platform, 'rel'))
  CMake:configure(pkg, options, "Release")
  CMake:build(pkg, options, "Release")
  CMake:install(pkg, options, "Release")
  print((">>> %s %s %s on %s_%s installed"):format(pkg.name, pkg.version, "rel", options.arch, ccpkg.target.platform))

  print((">>> Build for %s-%s %s"):format(options.arch, self.target.platform, 'dbg'))
  CMake:configure(pkg, options, "Debug")
  CMake:build(pkg, options, "Debug")
  CMake:install(pkg, options, "Debug")
  print((">>> %s %s %s on %s_%s installed"):format(pkg.name, pkg.version, "dbg", options.arch, ccpkg.target.platform))

  local f = os.path.join(pkg.debug_install_dir, "lib")
  local t = os.path.join(pkg.release_install_dir, "lib", "debug")
  os.copy(f, t, {override=1, recursive=1})
  os.rmdirs(pkg.debug_install_dir)
end