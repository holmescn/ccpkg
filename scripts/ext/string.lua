function string:strip()
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

function string:fmt(t)
  return self:gsub("$(%w+)", function (name)
    return t[name] and t[name] or '$' .. name
  end)
end

function string:join(t)
  return table.concat(t, self)
end