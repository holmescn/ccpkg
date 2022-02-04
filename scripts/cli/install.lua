local ccpkg = require "ccpkg"

return function (args)
  ccpkg.project = ccpkg:load_project("project.lua")
  local platform = ccpkg.project.target.platform

  print("host   os", os.name)
  print("target os", platform)
  print("project dir", os.curdir())
  print("project file", ccpkg.project_file)

  ccpkg.dirs = ccpkg:create_dirs()
  ccpkg.platform = require("platform." .. platform):init()

  local pkg_list = ccpkg:create_pkg_list()
  for _, x in ipairs(pkg_list) do
    local name, version = x:match("^(.*):(.*)$")
    ccpkg:install_pkg(name, version)
  end
end