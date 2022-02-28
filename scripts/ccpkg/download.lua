local Download = {}

function Download:checksum(pkg, full_path)
  local hash_type, hash_value = pkg.hash:match("sha(%d+):(%w+)")

  local filename = full_path .. ".sha" .. hash_type
  io.output(filename)
  io.write(("%s  %s"):format(hash_value, full_path))
  io.close()

  local ret = os.run("shasum -a " .. hash_type .. " " .. filename, {shell=1})
  os.remove(filename)

  return ret.exit_code == 0
end

function Download:url(pkg, url)
  local filename = os.path.basename(url)
  if pkg.filename then
    filename = pkg.filename:fmt {version=pkg.version}
  end

  local full_path = os.path.join(pkg.dirs.downloads, filename)
  pkg.data.downloaded = full_path

  if os.path.exists(full_path) then
    -- TODO check file size
    if self:checksum(pkg, full_path) then
      return
    end
    os.remove(full_path)
  end

  local curl_path = os.which("curl")
  if curl_path then
    local cmd = ("%s -o %s %s"):format(curl_path, full_path, url)
    assert(os.execute(cmd), ("download %s failed"):format(url))
  end
  assert(self:checksum(pkg, full_path), ("download %s failed"):format(url))
end

function Download:execute(pkg)
  if pkg.url_pattern then
    local url = pkg.url_pattern:fmt {version=pkg.version}
    self:url(pkg, url)
  elseif pkg.url then
    self:url(pkg, pkg.url)
  end
end

return Download