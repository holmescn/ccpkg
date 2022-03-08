---@diagnostic disable: undefined-field
local Args = require "ccpkg.args"
local BuildSystem = require "buildsystem"
local CMake = BuildSystem:new {
  name='cmake'
}

function CMake:init(pkg)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.cmake_path = os.which("cmake")
  o.ninja_path = os.which("ninja")
  assert(o.cmake_path, "cmake is not found")
  assert(o.ninja_path, "ninja is not found")
  return o
end

function CMake:create_opt(pkg, opt)
  opt.options = {}
  return opt
end

function CMake:before_configure(pkg, opt)
  opt.options['CMAKE_INSTALL_PREFIX'] = pkg.install_dir
  opt.options['CMAKE_FIND_ROOT_PATH'] = pkg.install_dir
  if pkg.configure_options then
    for option, value in pairs(pkg.configure_options) do
      opt.options[option] = value
    end
  end
end

function CMake:configure(pkg, opt)
  opt.args = Args:new {self.cmake_path}
  for k, v in table.sorted_pairs(opt.options) do
    opt.args:append("-D" .. k .. "=" .. v)
  end

  if self.ninja_path then
    opt.args:append("-GNinja")
  end

  opt.args:append(os.path.relpath(pkg.src_dir, pkg.build_dir))

  BuildSystem['configure'](self, pkg, opt)
end

function CMake:before_build(pkg, opt)
  opt.args = Args:new {
    self.cmake_path, "--build", ".", "--config", "Release"
  }
end

function CMake:before_install(pkg, opt)
  opt.args = Args:new {
    self.cmake_path, "--install", ".",
    "--prefix", pkg.install_dir,
    "--config", "Release"
  }
end

return CMake