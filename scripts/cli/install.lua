local ccpkg = require "ccpkg"

local function cmd(args)
  ccpkg.project = ccpkg:load_project("project.lua")
  local platform = ccpkg.project.target.platform

  print("host   os", os.name)
  print("target os", platform)
  print("project dir", os.curdir())
  print("project file", ccpkg.project_file)

  ccpkg.dirs = ccpkg:create_dirs()
  ccpkg.platform = require("platform." .. platform):init()

  for pkg_name, desc in pairs(ccpkg.project.dependencies) do
    ccpkg:check_pkg_exists(pkg_name)
  
    local pkg = require(pkg_name)
    ccpkg:check_version(pkg, desc.version)
  
    ccpkg:install_pkg(pkg)  
  end
end
return cmd
