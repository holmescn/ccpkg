function string:trim()
  return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function string:split(sep)
  sep = sep or "%s"
  local t = {}
  for part in self:gmatch("([^"..sep.."]+)") do
    table.insert(t, part)
  end
  return t
end

function table.dump(o, indent)
  if type(o) == "table" then
    indent = indent or 1
    local s = '{\n'
    for k, v in pairs(o) do
      -- indent
      s = s .. string.rep(' ', indent)
      -- key
      if type(k) == "string" then
        s = s .. '["'..k..'"] = '
      else
        s = s .. '['..k..'] = '
      end
      -- value
      s = s .. table.dump(v, indent+1) .. ',\n'
    end
  
    if indent == 1 then
      return s .. '}'
    else
      return s .. string.rep(' ', indent-1) .. '}'
    end
  elseif type(o) == "string" then
    return '"' .. o .. '"'
  else
    return tostring(o)
  end
end

function table.clone(o)
  if type(o) == "table" then
    local n = {}
    for k, v in pairs(o) do
      n[k] = table.clone(v)
    end
    return n
  else
    return o
  end
end

function table.contains(t, v)
  for _, e in ipairs(t) do
    if e == v then return true end
  end
  return false
end

function table.toarray(t)
  local r = {}
  for k, v in pairs(t) do
    if type(k) == "string" then
      table.insert(r, k .. "=" .. v)
    else
      table.insert(r, v)
    end
  end
  return r
end

function os.path.filename(s)
  return s:match("/([^/]+)$")
end

function create_pkg(o)
  o.data = {}
  setmetatable(o, { __index=o.data })
  return o
end
