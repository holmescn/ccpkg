local Args = require "ccpkg.args"
local BuildSystem = require "buildsystem"
local ConfigureMake = BuildSystem:new {
  name="configure_make",
}

function ConfigureMake:init(pkg)
  self.sh_path = os.which('sh')
  self.make_path = os.which('make')
  assert(self.sh_path, "shell is not found")
  assert(self.make_path, "make is not found")
  return self
end

function ConfigureMake:before_configure(pkg, opt)
  local relative_to_src = os.path.relpath(pkg.src_dir, pkg.build_dir)
  opt.args:insert( 1, os.path.join(relative_to_src, "configure") )
  opt.args:append("--prefix=" .. pkg.install_dir)

  opt['_args'] = opt.args
  opt.args = Args:new {
    self.sh_path, "-c", table.concat(opt.args, " ")
  }
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