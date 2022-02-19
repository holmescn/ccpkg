local Platform = {}
Platform.__index = Platform

function Platform:new(o)
  setmetatable(o, self)
  return o
end

return Platform