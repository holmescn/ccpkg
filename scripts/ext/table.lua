
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
