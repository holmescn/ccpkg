local Tools = require "tools"
local Download = {}

function Download:detect_downloader(tools, pkg)
  self.downloader = 'curl'
  if os.execute("curl --version 2>&1 > /dev/null") then return end
  self.downloader = nil
  assert(self.downloader, "no downloader found")
end

function Download:url_download(pkg)
  if not self.downloader then
    self:detect_downloader()
  end

  local url = pkg.url
  local filename = pkg.filename
  if not filename then
    filename = path.filename(url)
  end
  pkg.data.filename = filename

  local output = path.join {ccpkg.dirs.downloads, filename}
  if fs.exists(output) then
    if ccpkg:checksum(output, pkg.hash) then
      pkg.data.downloaded_file = output
      return
    else
      os.remove(output)
    end
  end

  if self.downloader == "curl" then
    local cmd = ("%s -o %s %s"):format(self.downloader, output, url)
    assert(os.execute(cmd), ("download %s failed"):format(url))
  end
  assert(fs.exists(output), ("download %s failed"):format(url))
  assert(ccpkg:checksum(output, pkg.hash), "the downloaded file is corrupted")
  pkg.data.downloaded_file = output
end

function Tools:download(pkg)
  if pkg.url then
    Download:url_download(pkg)
  end
end