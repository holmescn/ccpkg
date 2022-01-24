local Download = {}

function Download:detect_downloader(tools, pkg)
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
  local filename = opt.filename
  if not filename then
    filename = url:match("/([^/]+)$")
    opt.filename = filename
  end
  assert(filename, "filename is invalid")

  local output = os.path.join {ccpkg.dirs.downloads, filename}
  if self.downloader == "curl" then
    local cmd = ("%s -o %s %s"):format(self.downloader, output, url)
    assert(os.execute(cmd), ("download %s failed"):format(url))
  end
  assert(os.path.exists(output), ("download %s failed"):format(url))
  assert(ccpkg:checksum(output, pkg.hash), "the downloaded file is corrupted")
  pkg.data.downloaded_file = output
end

local function download(opt)
  if opt.url then
    Download:url(opt)
  end
end
return download