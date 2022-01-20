function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function table.dump(o, level)
  level = level or 1
  if type(o) == 'table' then
    local s = '{\n'
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. string.rep(' ', level) .. '['..k..'] = ' .. table.dump(v, level+1) .. ',\n'
    end
    return s .. '}'
  else
    return tostring(o)
  end
end

function table.clone(o)
  if type(o) == 'table' then
    local n = {}
    for k, v in pairs(o) do
      if type(v) == 'table' then
        n[k] = table.clone(o)
      else
        n[k] = v
      end
    end
    return n
  else
    return v
  end
end

function fs.create_dirs(dirs)
  local root = path.join {PROJECT_DIR, '.ccpkg'}
  if not fs.exists(root) then
     fs.mkdirs(root)
  end

  local ret_dirs = {}
  for _, dir in ipairs(dirs) do
     local p = path.join {root, dir}
     if not fs.exists(p) then
        fs.mkdirs(p)
     end
     ret_dirs[dir] = p
  end
  return ret_dirs
end

function path.filename(s)
  local m = s:match("/([%w-.]+)$")
  if m then return m end
end

function create_pkg(o)
  o.data = {}
  setmetatable(o, { __index=o.data })
  return o
end