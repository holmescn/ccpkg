local ccpkg = require "ccpkg"
local Extract = {}

function Extract:detect()
  if self.executable then return end

  if ccpkg:cmd_exists("tar") then
    self.executable = "tar"
  end
  assert(self.executable, "tar is not found")
end

function Extract:extract_dir(pkg)
  local pattern = pkg.version.extract_name or ("%s.*"):format(pkg.name)
  for _, dir in ipairs(os.listdir(ccpkg.dirs.tmp)) do
    local m = dir:match(pattern)
    if m then
      return os.path.join {ccpkg.dirs.tmp, m}
    end
  end
end

function ccpkg:extract(pkg)
  Extract:detect()

  local cmd = ("%s -C %s -xf %s"):format(Extract.executable, ccpkg.dirs.tmp, pkg.version.downloaded.full_path)
  assert(os.execute(cmd), "extract file failed")

  local extract_dir = Extract:extract_dir(pkg)
  local src_dir = extract_dir .. '-src'
  os.rename(extract_dir, src_dir)
  pkg.src_dir = src_dir
end
return ccpkg.extract