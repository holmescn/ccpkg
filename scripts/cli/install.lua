local ccpkg = require "ccpkg"

local function install_pkg(pkg_name, desc)
  local pkg_path = os.path.join {ccpkg.root_dir, "ports", pkg_name}
  assert(os.path.exists(pkg_path), ("unknown pkg %s"):format(pkg_name))

  local pkg = require(pkg_name)
  ccpkg:check_version(pkg, desc.version)

  -- TODO handle depends of the pkg

  if not ccpkg:check_downloaded(pkg) then
    ccpkg:download(pkg)
  end
  ccpkg:extract(pkg)

  for _, arch in ipairs(ccpkg.project.target.arch) do
    local opt = ccpkg:create_opt(pkg, desc, arch)
    if not ccpkg:check_installed(opt) then
      ccpkg[pkg.buildsystem](ccpkg, opt)
    else
      print((">>> %s on %s is installed"):format(opt.versioned_name, opt.arch_platform))
    end
  end
end

local function cmd(args)
  print("host os name", os.name)
  print("project dir", os.curdir())

  ccpkg.project = ccpkg:load_project("project.lua")
  print("target     ", ccpkg.project.target.platform)

  ccpkg.dirs = ccpkg:create_dirs {"tmp", "downloads", "installed"}

  for pkg_name, desc in pairs(ccpkg.project.dependencies) do
    install_pkg(pkg_name, desc)
  end
end
return cmd
