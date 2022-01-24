local ccpkg = require "ccpkg"
local Download = {}

function Download:detect_downloader()
  if ccpkg:cmd_exists("curl") then
    self.downloader = 'curl'
  end
  assert(self.downloader, "no downloader found")
end

function Download:url(opt)
  if not self.downloader then
    self:detect_downloader()
  end

  local url = opt.url
  if self.downloader == "curl" then
    local cmd = ("%s -o %s %s"):format(self.downloader, opt.downloaded.full_path, url)
    assert(os.execute(cmd), ("download %s failed"):format(url))
  end
  assert(os.path.exists(opt.downloaded.full_path), ("download %s failed"):format(url))
  assert(ccpkg:checksum(opt), "the downloaded file is corrupted")
end

function ccpkg:download(opt)
  if opt.url then
    Download:url(opt)
  end
end
return ccpkg.download