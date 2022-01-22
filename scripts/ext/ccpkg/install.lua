function ccpkg:install(args)
  print("os name ", os.name)
  print("project dir", self.root_dir)

  self:generate_toolchain_file()
  for pkg_name, info in pairs(self.cfg.dependencies) do
    ccpkg:install_pkg(pkg_name, info)
  end  
end

function ccpkg:install_pkg(pkg_name, info)
  local pkg_path = os.path.join {ccpkg.root_dir, "ports", pkg_name}
  assert(os.path.exists(pkg_path), ("unknown pkg %s"):format(pkg_name))

  local pkg = require(pkg_name)
  ccpkg:check_version(pkg, info)

  -- TODO handle depends of the pkg

  self:download(pkg)
  self:extract(pkg)
  if type(self.target.arch) == "table" then
    for _, arch in ipairs(self.target.arch) do
      pkg:script(arch)
    end
  else
    pkg:script(self.target.arch)
  end
end
