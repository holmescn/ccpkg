local ccpkg = require "ccpkg"
local ConfigureMake = {
  paths={},
  executables={}
}

function ConfigureMake:init()
  local bash, bash_path = ccpkg:cmd_paths("bash")
  local make, make_path = ccpkg:cmd_paths("make")
  assert(bash, "bash is not found")
  assert(make, "make is not found")
  if not table.contains(self.paths, bash_path) then
    table.insert(self.paths, bash_path)
  end
  if not table.contains(self.paths, make_path) then
    table.insert(self.paths, make_path)
  end
  self.executables.bash = bash
  self.executables.make = make
  return self
end

function ConfigureMake:start(opt)
  ccpkg.platform:configure_make(opt)
  table.insert(self.paths, 1, os.path.join(ccpkg.platform.llvm_path, "bin"))
  opt.envs["PATH"] = self.paths
  opt.envs = ccpkg:transform_envs(opt.envs)
end

function ConfigureMake:configure(opt, debug)
  local relative_to_src = os.path.relative(opt.src_dir, os.curdir())
  local args = {
    os.path.join(relative_to_src, "configure"),
  }
  if opt.args then
    args = table.append(args, opt.args)
  end

  table.insert(args, "--prefix")
  local install_dir = ccpkg:install_dir(opt, debug)
  table.insert(args, install_dir)

  local cmdline = table.concat(args, ' ')
  args = {
    self.executables.bash, '-c', cmdline
  }

  return {
    cmd=self.executables.bash, args=args, envs=opt.envs
  }
end

function ConfigureMake:build(opt, debug)
  return {cmd=self.executables.make, envs=opt.envs,
    args={
      self.executables.make, "-j4"
    }
  }
end

function ConfigureMake:install(opt, debug)
  return {cmd=self.executables.make, envs=opt.envs,
    args={
      self.executables.make, "install"
    }
  }
end

function ConfigureMake:finalize(opt)
end

return ConfigureMake