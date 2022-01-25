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
  for _, dir in ipairs(os.listdir(ccpkg.dirs.tmp)) do
    if dir == pkg.current.extract_name then
      return os.path.join {ccpkg.dirs.tmp, dir}
    else
      if dir:match(("%s.*"):format(pkg.name)) then
        return os.path.join {ccpkg.dirs.tmp, dir}
      end
    end
  end
end

function Extract:remove_old_dirs(pkg)
  for _, dir in ipairs(os.listdir(ccpkg.dirs.tmp)) do
    local full_path = os.path.join(ccpkg.dirs.tmp, dir)
    if full_path:match(pkg.name .. ".*-src$") then
      os.rmdirs(full_path)
    end
  end
end

function ccpkg:extract(pkg)
  Extract:detect()
  Extract:remove_old_dirs(pkg)

  local cmd = ("%s -C %s -xf %s"):format(Extract.executable, ccpkg.dirs.tmp, pkg.current.downloaded.full_path)
  assert(os.execute(cmd), "extract file failed")

  local extract_dir = Extract:extract_dir(pkg)
  local src_dir = extract_dir .. '-src'
  os.rename(extract_dir, src_dir)
  pkg.src_dir = src_dir
end
return ccpkg.extract
