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

function string:fmt(o)
  local s = self:gsub("$(%w+)", function (n)
    return o[n] and o[n] or '$' .. n
  end)
  return s
end