---@diagnostic disable: undefined-field
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

  local full_path = os.path.join(pkg.project.dirs.downloads, filename)
  pkg.downloaded = full_path

  if os.path.exists(full_path) then
    -- TODO check file size
    if self:checksum(pkg, full_path) then
      return
    end
    os.remove(full_path)
  end

  local cmd = nil
  local axel_path = os.which("axel")
  local curl_path = os.which("curl")
  local wget_path = os.which("wget")
  if axel_path then
    cmd = ("%s --search=4 --num-connections=4 --output=%s %s"):format(axel_path, full_path, url)
  elseif wget_path then
    cmd = ("%s --continue --tries=3 --output-file=%s %s"):format(wget_path, full_path, url)
  elseif curl_path then
    cmd = ("%s --retry 3 --parallel --output %s %s"):format(curl_path, full_path, url)
  else
    error("no download program found, support: axel, wget and curl")
  end
  print("--- downloading " .. url .. ' -> ' .. os.path.relpath(full_path, pkg.project_dir))
  assert(os.execute(cmd), ("download %s failed"):format(url))
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