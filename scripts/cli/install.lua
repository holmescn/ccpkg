
local function install_pkg(pkg_name, desc)
  local pkg_path = os.path.join {ccpkg.root_dir, "ports", pkg_name}
  assert(os.path.exists(pkg_path), ("unknown pkg %s"):format(pkg_name))

  local pkg = require(pkg_name)
  ccpkg:check_version(pkg, desc.version)

  local opt = ccpkg:create_opt(pkg, desc)

  -- TODO handle depends of the pkg

  if not ccpkg:downloaded(opt) then
    assert(false)
    -- ccpkg.download(opt)
    -- ccpkg:extract(opt)
  end
  assert(false)

  -- for _, arch in ipairs(ccpkg.project.target.arch) do
  --   opt.arch = arch
  --   opt.arch_platform = ("%s_%s"):format(arch, ccpkg.project.target.platform)
  --   if not ccpkg:installed(pkg) then
  --     pkg:script(opt)
  --   end
  -- end
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