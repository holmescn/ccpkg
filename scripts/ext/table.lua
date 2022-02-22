-- Extend table library
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
    local t = {}
    for k, v in pairs(o) do
      t[k] = table.clone(v)
    end
    return t
  else
    return o
  end
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

function table.index(t, v)
  for index, value in pairs(t) do
    if v == value then
      return index
    end
  end
end

function table.remove_then_insert(t, insert_index, value)
  local index = table.index(t, value)
  if index and index ~= insert_index then
    table.remove(t, index)
    table.insert(t, insert_index, value)
  end
end