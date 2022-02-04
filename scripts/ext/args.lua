local Args = {}

function Args:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function Args:append(o)
  if type(o) == "table" then
    for _, v in ipairs(o) do
      table.insert(self, v)
    end
  elseif type(o) == "string" then
    table.insert(self, o)
  else
    error("bad argument #1: string or table expected, got " .. type(o))
  end
  return self
end

return Args
