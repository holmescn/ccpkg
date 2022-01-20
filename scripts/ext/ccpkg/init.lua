local function search(t, k)
  if t.cfg[k] then return t.tools[k] end
  if t.tools[k] then return t.tools[k] end
end

setmetatable(ccpkg, {
  __index=search
})

function ccpkg:load(filename)
  local cfg_file = path.join {PROJECT_DIR, filename}
  assert(fs.exists(cfg_file), ("%s not found in %s"):format(filename, PROJECT_DIR))

  self.cfg = dofile(cfg_file)
  self.dirs = fs.create_dirs {"tmp", "downloads", "installed"}
  self.tools = require "tools"
  self.platform = require('platform.' .. self.cfg.target.platform)

  require "tools.checksum"
  require "tools.download"
  require "tools.extract"
  require "tools.cmake"
end

require("ext.ccpkg.install")
