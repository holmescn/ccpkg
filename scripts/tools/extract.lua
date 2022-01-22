local Tools = require "tools"
local Extract = {}

function Extract:detect()
  if ccpkg:cmd_exists("tar") then
    self.executable = "tar"
  end
  assert(self.executable, "tar is not found")
end

function Tools:extract(pkg)
  Extract:detect()

  local cmd = ("%s -C %s -xf %s"):format(Extract.executable, ccpkg.dirs.tmp, pkg.downloaded_file)
  assert(os.execute(cmd), "extract file failed")

  local pattern = pkg.extract_name or ("%s.*"):format(pkg.name)
  for _, s in ipairs(os.listdir(ccpkg.dirs.tmp)) do
    local m = s:match(pattern)
    if m then
      pkg.data.src_dir = os.path.join {ccpkg.dirs.tmp, m}
      break
    end
  end
  local new_src_dir = pkg.src_dir .. '-src'
  os.rename(pkg.src_dir, new_src_dir)
  pkg.data.src_dir = new_src_dir
end
