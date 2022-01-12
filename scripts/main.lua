-- Print the current settings
print(string.format("HOST ARCH  : %s", ccpkg.host_arch))
print(string.format("HOST SYSTEM: %s", ccpkg.host_system))
print(string.format("CCPKG_ROOT : %s", ccpkg.root_dir))
print(string.format("CURRENT DIR: %s", ccpkg.currrent_dir))

os.path_join = function (root, ...)
  local sep = '/'
  local p = root
  local n_args = select("#", ...)
  if string.find(root, '.:\\') ~= nil then
    sep = '\\'
  end

  for i = 1, n_args do
    local arg = select(i, ...)
    p = p .. sep .. arg
  end
  return p
end

package.path = '?;?.lua;' .. os.path_join(ccpkg.root_dir, "scripts", "?.lua")

local argparse = require "3rdparty.argparse"
local parser = argparse("ccpkg", "An example.")

parser:argument("input", "Input file.")
parser:option("-o --output", "Output file.", "a.out")
parser:option("-I --include", "Include locations."):count("*")

local args = parser:parse()

function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

print(dump(args))
