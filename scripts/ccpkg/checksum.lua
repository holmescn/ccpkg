local ccpkg = require "ccpkg"
local CheckSum = {}

function CheckSum:detect()
  if self.executable then return end

  self.executable = "shasum"
  if os.execute("shasum -v 2>&1 > /dev/null") then return end
  self.executable = nil
  assert(self.executable, "shasum is not found")
end

function CheckSum:generate_sig_file(full_path, hash_value)
  local filename = full_path .. ".sig"
  io.output(filename)
  io.write(("%s  %s"):format(hash_value, full_path))
  io.close()
  return filename
end

function ccpkg:checksum(pkg)
  CheckSum:detect()

  local hash_type, hash_value = pkg.current.hash:match("sha(%d+):(%w+)")
  local sig_file = CheckSum:generate_sig_file(pkg.current.downloaded.full_path, hash_value)
  local cmd = ("%s -a %s -c %s"):format(CheckSum.executable, hash_type, sig_file)
  local ok = os.execute(cmd)
  os.remove(sig_file)
  return ok
end
return ccpkg.checksum