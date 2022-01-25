local ccpkg = require "ccpkg"
local CMake = {
  paths={}
}

function CMake:init(pkg)
  local cmake, cmake_path = ccpkg:cmd_paths("cmake")
  assert(cmake, "no cmake found in current $PATH")
  self.cmake = cmake
  if not table.contains(self.paths, cmake_path) then
    table.insert(self.paths, cmake_path)
  end

  if ccpkg:cmd_exists('ninja') then
    local ninja, ninja_path = ccpkg:cmd_paths("ninja")
    if not table.contains(self.paths, ninja_path) then
      table.insert(self.paths, ninja_path)
    end
    self.ninja = ninja
  end
  return self
end

function CMake:start(opt)
  ccpkg.platform:cmake(opt)
  opt.envs = ccpkg:transform_envs({PATH=self.paths})
end

function CMake:options_to_args(options)
  local args = {}
  for k, v in pairs(options) do
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

function CMake:configure(opt, debug)
  local args = {self.cmake}

  if type(opt.args) == "table" then
    args = table.append(args, opt.args)
  end

  args = table.append(args, self:options_to_args(opt.options))

  table.insert(args, opt.src_dir)

  return {cmd=self.cmake, args=args, envs=opt.envs}
end

function CMake:build(opt, debug)
  local config = debug and "Debug" or "Release"
  return {
    cmd=self.cmake, envs=opt.envs,
    args={self.cmake, "--build", ".", "--config", config}
  }
end

function CMake:install(opt, debug)
  local config = debug and "Debug" or "Release"
  local install_dir = debug and opt.install_dir.dbg or opt.install_dir.rel

  return {
    cmd=self.cmake, envs=opt.envs,
    args={
      self.cmake,
      "--install", ".",
      "--prefix", install_dir,
      "--config", config
    }
  }
end

function CMake:finalize(opt)
end

return CMake