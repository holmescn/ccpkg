---@diagnostic disable: undefined-field
local Args = require "ccpkg.args"
local BuildSystem = require "buildsystem"
local ConfigureMake = BuildSystem:new {
  name="configure_make",
}

function ConfigureMake:init(pkg)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.sh_path = os.which('sh')
  o.make_path = os.which('make')
  assert(o.sh_path, "shell is not found")
  assert(o.make_path, "make is not found")
  return o
end

function ConfigureMake:create_opt(pkg, opt)
  opt.args = Args:new {}
  return opt
end

function ConfigureMake:before_configure(pkg, opt)
  local relative_to_src = os.path.relpath(pkg.src_dir, pkg.build_dir)
  opt.args:insert( 1, os.path.join(relative_to_src, "configure") )
  opt.args:add("--prefix=" .. pkg.install_dir)
  if pkg.configure_options then
    for option in table.each(pkg.configure_options) do
      opt.args:add(option)
    end
  end
end

function ConfigureMake:configure(pkg, opt)
  opt.args = Args:new {
    self.sh_path, "-c", table.concat(opt.args, " ")
  }
  BuildSystem['configure'](self, pkg, opt)
end

function ConfigureMake:before_build(pkg, opt)
  opt.args = Args:new {
    self.make_path, "--jobs", pkg.project.args.jobs
  }
end

function ConfigureMake:before_install(pkg, opt)
  opt.args = Args:new {
    self.make_path, "install"
  }
end

return ConfigureMake