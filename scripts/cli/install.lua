---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local Command = {}

function Command:init(parser)
  local cmd = parser:command("install i", "Install the project")
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
  project.dirs = ccpkg:makedirs(project_dir)
  project.args = args

  -- TODO resolve dependencies and versions
  self:do_install(project.dependencies, project)
end

function Command:do_install(dependencies, project)
  for spec in table.each(dependencies) do
    local pkg = nil
    if type(spec) == "string" then
      pkg = require('ports.' .. spec):new(project, {name=spec, version='latest'})
    else
      pkg = require('ports.' .. spec.name):new(project, spec)
    end

    self:do_install(pkg:dependencies(), project)

    pkg:download_source()
    for tuplet in table.each(project.tuplets) do
      local machine, platform_name = tuplet:match("(%w+)-(%w+)")
      local platform = require('platform.' .. platform_name):init(project)

      pkg.tuplet = tuplet
      pkg.machine = machine
      pkg.platform = platform
      if not pkg:is_installed() then
        self:install_pkg(pkg)
      end
    end
  end
end

function Command:install_pkg(pkg)
  print (("--- build %s-%s for %s"):format(pkg.name, pkg.version, pkg.tuplet))

  pkg:unpack_source()
  pkg:patch_source()

  pkg:before_build_steps()
  for step in table.each {"configure", "build", "install"} do
    local opt = pkg.buildsystem:create_opt(pkg, {env=table.clone(pkg.env), check=true})

    print("--- " .. step .. " step")
    pkg.platform:execute(step, pkg, opt)
    pkg.buildsystem:execute_hook('before', step, pkg, opt)
    pkg:execute_hook("before", step, opt)
    pkg:execute(step, opt)
    pkg:execute_hook("after", step, opt)
    pkg.buildsystem:execute_hook('after', step, pkg, opt)
  end
  pkg:after_build_steps()
end

return Command
