local function search(t, k)
  if t.cfg[k] then return t.cfg[k] end
  if t.tools[k] then return t.tools[k] end
end

setmetatable(ccpkg, {
  __index=search
})

function ccpkg:init(filename)
  local cfg_file = path.join {os.currentdir(), filename}
  assert(fs.exists(cfg_file), ("%s not found in current folder"):format(filename))

  self.cfg = dofile(cfg_file)
  self.dirs = fs.create_dirs {"tmp", "downloads", "installed"}
  self.tools = require "tools"
  self.platform = require('platform.' .. self.cfg.target.platform)

  require "tools.checksum"
  require "tools.download"
  require "tools.extract"
  require "tools.cmake"

  self:generate_toolchain_file()
end

function ccpkg:generate_toolchain_file()
  local toolchain_file = path.join {self.dirs.working_dir, self.target.platform .. ".toolchain.cmake"}
  self.cfg.toolchain_file = toolchain_file

  if fs.exists(toolchain_file) then
    os.remove(toolchain_file)
  end

  local ofile = io.output(toolchain_file)
  self.platform:toolchain_file(ofile)
  ofile:close()
end

function ccpkg:cmd_exists(cmd_name)
  local cmd = ("which %s > /dev/null"):format(cmd_name)
  local exists = os.execute(cmd)
  return exists
end

function ccpkg:cmd_full_path(cmd_name)
  local cmd = ("which %s"):format(cmd_name)
  local h = io.popen(cmd, "r")
  local r = h:read("*all"):trim()
  h:close()
  return r
end

function ccpkg:common_paths()
  local home = os.getenv("HOME")
  return {
    "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin",
    path.join {home, ".local", "bin"}
  }
end

require("ext.ccpkg.install")