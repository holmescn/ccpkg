local ccpkg = require "ccpkg"
local Command = {}

function Command:init(parser)
  local cmd = parser:command("install i", "Install the project")
  cmd:option "-c" "--project_file"
    :description "Specify the project file."
    :default "project.lua"
  cmd:option "-j" "--jobs"
    :description "Allow N jobs at once."
    :default "2"

  parser.commands['install'] = self
end

function Command:execute(args)
  local project_file = os.path.realpath(args.project_file)
  local project_dir = os.path.dirname(project_file)
  print("--- project dir  " .. project_dir)
  print("--- project file " .. project_file)

  local project = dofile(project_file)
  local platform = require('platform.' .. project.platform):init(project)
  project.dirs = ccpkg:makedirs(project_dir)
  project.args = args

  -- TODO resolve dependencies and versions
  for arch in table.iterate(project.arch) do
    self:do_install(project.dependencies, arch, project, platform)
  end
end

function Command:do_install(dependencies, arch, project, platform)
  for name, desc in table.sorted_pairs(dependencies) do
    local pkg = require('ports.' .. name):init(arch, desc)
    pkg.project = project
    pkg.platform = platform
    pkg.data.target = arch .. '-' .. platform.name
    self:do_install(pkg:dependencies(), arch, project, platform)
    if not pkg:is_installed() then
      self:install_pkg(pkg)
    end
  end
end

function Command:install_pkg(pkg)
  print (("--- build %s-%s for %s-%s"):format(pkg.name, pkg.version, pkg.arch, pkg.platform.name))

  pkg:download_source()
  pkg:unpack_source()
  pkg:patch_source()
  pkg:makedirs()

  local files = os.path.snapshot(pkg.install_dir)

  pkg:before_build_steps()
  for step in table.iterate {"configure", "build", "install"} do
    local opt = {env=table.clone(pkg.env), check=true}
    print("--- " .. step .. " step")
    pkg.platform:execute(step, pkg, opt)
    pkg.buildsystem:execute_hook('before', step, pkg, opt)
    pkg:execute_hook("before", step, opt)
    pkg:execute(step, opt)
    pkg:execute_hook("after", step, opt)
    pkg.buildsystem:execute_hook('after', step, pkg, opt)
  end
  pkg:after_build_steps()
  pkg:save_package(files)
end

return Command