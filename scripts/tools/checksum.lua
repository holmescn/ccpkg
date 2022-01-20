local Tools = require "tools"
local CheckSum = {}

function CheckSum:detect()
  self.executable = "shasum"
  if os.execute("shasum -v 2>&1 > /dev/null") then return end
  self.executable = nil
  assert(self.executable, "shasum is not found")
end

function CheckSum:generate_sig_file(output, hash_value)
  local filename = output .. ".sig"
  io.output(filename)
  io.write(("%s  %s"):format(hash_value, output))
  io.close()
  return filename
end

function Tools:checksum(output, hash)
  if not CheckSum.executable then
    CheckSum:detect()
  end

  local hash_type, hash_value = hash:match("sha(%d+):(%w+)")
  local sig_file = CheckSum:generate_sig_file(output, hash_value)
  local cmd = ("%s -a %s -c %s"):format(CheckSum.executable, hash_type, sig_file)
  local ok, exit, status = os.execute(cmd)
  os.remove(sig_file)
  return ok
end
