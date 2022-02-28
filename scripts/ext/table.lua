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

  local iterator, s, i = ipairs(keys)

  return function (state)
    local next_i, k = iterator(state, i)
    i = next_i
    return k, t[k]
  end, s, i
end

function table.values(t)
  return table.each(t, pairs)
end

function table.each(t, f)
  f = f or ipairs
  local iterator, s, i = f(t)

  return function(state)
    local next_i, v = iterator(state, i)
    i = next_i
    return v
  end, s, i
end

function table.index(t, v)
  for index, value in pairs(t) do
    if v == value then
      return index
    end
  end
end

function table.serialize(o, indent)
  indent = indent or 0
  if type(o) == "table" then
    local s = '{\n'
    indent = indent + 2
    for k, v in table.sorted_pairs(o) do
      -- indent
      s = s .. string.rep(' ', indent)
      -- key
      if type(k) == "string" then
        if k:match('[/\\-]') then
          s = s .. '["'..k..'"]='
        else
          s = s .. k ..'='
        end
      end
      -- value
      s = s .. table.serialize(v, indent) .. ',\n'
    end
    indent = indent - 2
    if indent == 0 then
      return s .. '}'
    else
      return s .. string.rep(' ', indent) .. '}'
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

function table.create_filter(t)
  local filter = {}
  for v in table.each(t) do
    filter[v] = true
  end
  return filter
end
