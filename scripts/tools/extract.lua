local Tools = require "tools"
local Extract = {}

function Extract:detect()
  self.executable = "tar"
  if os.execute("tar --version 2>&1 > /dev/null") then return end
  self.executable = nil
  assert(self.executable, "tar is not found")
end

function Tools:extract(pkg)
  if not Extract.executable then
    Extract:detect()
  end

  local cmd = ("tar -C %s -xf %s"):format(ccpkg.dirs.tmp, pkg.downloaded_file)
  assert(os.execute(cmd), "extract file failed")

  local files = fs.listdir(self.dirs.tmp)
  local pattern = pkg.name .. ".*"
  for _, s in ipairs(files) do
    local m = s:match(pattern)
    if m then
      pkg.data.src_dir = path.join {ccpkg.dirs.tmp, m}
      break
    end
  end
  os.rename(pkg.src_dir, pkg.src_dir .. '-src')
  pkg.data.src_dir = pkg.data.src_dir .. '-src'
end
