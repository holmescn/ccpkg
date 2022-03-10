local Args = {}

function Args:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Args:insert(...)
  table.insert(self, ...)
end

function Args:contains(opt)
  for _, v in ipairs(self) do
    if v == opt then
      return true
    end
  end
  return false
end

function Args:add(opt)
  if not self:contains(opt) then
    table.insert(self, opt)
  end
end

function Args:remove(opt)
  local index = nil
  for i, v in ipairs(self) do
    if v == opt then
      index = i
      break
    end
  end
  if index then
    table.remove(self, index)
  end
end

function Args:remove_with_prefix(prefix)
  local index = nil
  for i, v in ipairs(self) do
    if v:startswith(prefix) then
      index = i
      break
    end
  end
  if index then
    table.remove(self, index)
  end
end

return Args