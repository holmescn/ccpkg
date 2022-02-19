
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

function table.contains(t, v)
  for _, e in ipairs(t) do
    if e == v then return true end
  end
  return false
end

function table.sorted_pairs(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)

  local i = 0
  local n = #keys
  return function ()
    i = i + 1
    if i <= n then return keys[i], t[keys[i]] end
  end
end

function table.iterate(t)
  local i = 0
  local n = #t
  return function(t)
    i = i + 1
    if i <= n then return t[i] end
  end, t
end