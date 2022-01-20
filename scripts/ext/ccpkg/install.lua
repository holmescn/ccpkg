function ccpkg:install(args)
  print("project dir", PROJECT_DIR)
  print("os name ", os.name)
  print("platform", self.cfg.target.platform)

  for pkg_name, info in pairs(self.cfg.dependencies) do
    ccpkg:install_pkg(pkg_name, info)
  end  
end

function ccpkg:install_pkg(pkg_name, info)
  local pkg_path = path.join {CCPKG_ROOT_DIR, "ports", pkg_name}
  assert(fs.exists(pkg_path), ("unknown pkg %s"):format(pkg_name))

  local pkg = require(pkg_name)
  ccpkg:check_version(pkg, info)

  -- TODO handle depends of the pkg

  ccpkg:download(pkg)
  ccpkg:extract(pkg)
  pkg:install()
end
