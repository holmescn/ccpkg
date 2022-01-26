local ccpkg = require "ccpkg"

function ccpkg:install_pkg(pkg)
  -- TODO handle depends of the pkg

  if not self:check_downloaded(pkg) then
    self:download(pkg)
  end
  self:extract(pkg)
  print(">>> source dir: " .. pkg.src_dir)

  self.buildsystem = require("buildsystem." .. pkg.buildsystem):init(pkg)

  for _, arch in ipairs(ccpkg.project.target.arch) do
    local opt = ccpkg:create_opt(pkg, arch)
    if not ccpkg:check_installed(opt) then
      local pwd = os.curdir()
      self.buildsystem:start(opt)
      if opt.pkg['patch_source'] then
        print(">>> Patch source")
        opt.pkg:patch_source(self, opt)
      end
      self:build_process(opt, true)
      self:build_process(opt, false)

      -- move <dbg_install_dir>/lib to <rel_install_dir>/lib/debug
      os.copy(os.path.join(opt.install_dir.dbg, "lib"),
              os.path.join(opt.install_dir.rel, "lib", "debug"))
      os.rmdirs(opt.install_dir.dbg)

      self.buildsystem:finalize(opt)
      os.chdir(pwd)
    else
      print((">>> %s on %s is installed"):format(opt.versioned_name, opt.arch_platform))
    end
  end
end

function ccpkg:build_process(opt, debug)
  local cmd = nil
  local suffix = debug and "dbg" or "rel"

  print((">>> Build for %s-%s"):format(opt.target_triplet, suffix))

  opt.build_dir = self:build_dir(opt, suffix)
  os.mkdirs(opt.build_dir)
  os.chdir(opt.build_dir)

  print(">>> Configuring")
  self:call_pkg_hook("before_configure", opt)
  cmd = self.buildsystem:configure(opt, debug)
  cmd.out = ccpkg:log_filename(opt, "config", suffix)
  assert(os.run(cmd) == 0, "configure failed")

  print(">>> Building")
  self:call_pkg_hook("before_build", opt)
  cmd = self.buildsystem:build(opt, debug)
  cmd.out = ccpkg:log_filename(opt, "build", suffix)
  assert(os.run(cmd) == 0, "build failed")

  local install_dir = ccpkg:install_dir(opt, debug)
  os.mkdirs(install_dir)

  opt.install_dir = opt.install_dir or {}
  opt.install_dir[suffix] = install_dir

  print(">>> Installing to " .. install_dir)
  self:call_pkg_hook("before_install", opt)
  cmd = self.buildsystem:install(opt, debug)
  cmd.out = ccpkg:log_filename(opt, "install", suffix)
  if os.run(cmd) ~= 0 then
    os.rmdirs(install_dir)
    error(">>> Install Failed")
  end
  print((">>> %s %s-%s installed"):format(opt.versioned_name, opt.target_triplet, suffix))
end

return ccpkg.install_pkg