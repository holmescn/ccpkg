local Args = {}
Args.__index = Args

function Args:new(o)
  o = o or {}
  setmetatable(o, self)
  return o
end

function Args:insert(...)
  table.insert(self, ...)
end

function Args:append(...)
  local n = select('#', ...)
  for i = 1, n do
    table.insert(self, select(i, ...))
  end
  return self
end

function Args:extend(t)
  for v in table.each(t) do
    table.insert(self, v)
  end
  return self
end

return Args