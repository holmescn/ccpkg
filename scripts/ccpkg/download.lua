local ccpkg = require "ccpkg"
local Download = {}

function Download:detect_downloader()
  if self.downloader then return end

  if ccpkg:cmd_exists("curl") then
    self.downloader = 'curl'
  end
  assert(self.downloader, "no downloader found")
end

function Download:url(pkg)
  self:detect_downloader()

  local url = pkg.current.url
  if self.downloader == "curl" then
    local cmd = ("%s -o %s %s"):format(self.downloader, pkg.current.downloaded.full_path, url)
    assert(os.execute(cmd), ("download %s failed"):format(url))
  end
  assert(os.path.exists(pkg.current.downloaded.full_path), ("download %s failed"):format(url))
  assert(ccpkg:checksum(pkg), "the downloaded file is corrupted")
end

function ccpkg:download(pkg)
  if pkg.current.url then
    Download:url(pkg)
  end
end

return ccpkg.download