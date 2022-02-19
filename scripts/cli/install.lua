local ccpkg = require "ccpkg"

local function install_pkg(pkg)
  if pkg:is_installed() then return end
  print (("--- build %s-%s on %s-%s"):format(pkg.name, pkg.version, pkg.arch, pkg.platform.name))

  -- local files = os.snapshot_files(pkg.installed_dir)

  pkg:download_source()
  pkg:unpack_source()
  pkg:patch_source()

  pkg.platform:execute("before_build_steps", pkg)
  pkg:before_build_steps()
  for step in table.iterate {"configure", "build", "install"} do
    pkg:execute("before_" .. step)
    pkg.buildsystem:execute('before_' .. step, pkg)
    pkg.platform:execute(step, pkg)
    pkg.buildsystem:execute(step, pkg)
    pkg:execute("after_" .. step)
    pkg.buildsystem:execute('after_' .. step, pkg)
  end
  pkg:after_build_steps()
  pkg.platform:execute("after_build_steps", pkg)
  -- pkg:save_package(files)
end

local function do_install(dependencies, arch, project, platform)
  for name, desc in table.sorted_pairs(dependencies) do
    local pkg = require('ports.' .. name):init(arch, desc)
    pkg.project = project
    pkg.platform = platform
    do_install(pkg.dependencies, arch, project, platform)
    install_pkg(pkg)
  end
end

return function (args)
  local project_file = os.path.realpath(args.project_file)
  local project_dir = os.path.dirname(project_file)
  print("--- project dir  " .. project_dir)
  print("--- project file " .. project_file)

  local project = dofile(project_file)
  local platform = require('platform.' .. project.platform):init(project)
  project.args = args
  project.dirs = ccpkg:create_dirs(project_dir)

  -- TODO resolve dependencies and versions
  for arch in table.iterate(project.arch) do
    do_install(project.dependencies, arch, project, platform)
  end
end