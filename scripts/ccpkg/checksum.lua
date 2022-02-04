local ccpkg = require "ccpkg"
local CheckSum = {}

function CheckSum:generate_sig_file(full_path, hash_value)
  local filename = full_path .. ".sig"
  io.output(filename)
  io.write(("%s  %s"):format(hash_value, full_path))
  io.close()
  return filename
end

function ccpkg:checksum(pkg, version)
  assert(os.search_path("shasum"), "shasum is not found")

  local h = pkg.versions[version].hash
  local hash_type, hash_value = h:match("sha(%d+):(%w+)")
  local sig_file = CheckSum:generate_sig_file(pkg.data.downloaded.full_path, hash_value)
  local ok = os.run {cmd="shasum -a " .. hash_type .. " " .. sig_file, null=1}
  os.remove(sig_file)
  return ok
end
return ccpkg.checksum