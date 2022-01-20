local Tools = {}

function Tools:check_version(pkg, info)
  local version = pkg.versions[info.version]
  assert(version, ("unknown version '%s' of %s"):format(info.version, pkg.name))
  for k, v in pairs(version) do
    pkg.data[k] = v
  end
  pkg.data.version = info.version
end

return Tools