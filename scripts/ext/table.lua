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

function table.serialize(o, level)
  level = level or 1
  if type(o) == "table" then
    local s = '{\n'
    for k, v in table.sorted_pairs(o) do
      -- indent
      s = s .. string.rep(' ', 2*level)
      -- key
      if type(k) == "string" then
        if k:match('[/\\-]') then
          s = s .. '["'..k..'"]='
        else
          s = s .. k ..'='
        end
      end
      -- value
      s = s .. table.serialize(v, level+1) .. ',\n'
    end
  
    if level == 1 then
      return s .. '}'
    else
      return s .. string.rep(' ', 2*(level-1)) .. '}'
    end
  elseif type(o) == "string" then
    return '"' .. o .. '"'
  else
    return tostring(o)
  end
end

function table.len(t, f)
  f = f or pairs
  local n = 0
  for _, _ in f(t) do
    n = n + 1
  end
  return n
end

