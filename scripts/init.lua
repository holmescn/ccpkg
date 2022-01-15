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
ccpkg.root_dir = os.getenv("CCPKG_ROOT")
ccpkg.project_dir = ccpkg.getcwd()
ccpkg.chdir(os.path_join(ccpkg.root_dir, 'scripts'))
ccpkg.path_sep = '/'
if string.find(ccpkg.root_dir, '.:\\') ~= nil then
  ccpkg.path_sep = '\\'
end

package.path = '?.lua;?' .. ccpkg.path_sep .. 'init.lua'
local argparse = require('3rdparty.argparse')
local parser = argparse("ccpkg", "An example.")

parser:argument("input", "Input file.")
parser:option("-o --output", "Output file.", "a.out")
parser:option("-I --include", "Include locations."):count("*")

local args = parser:parse(ARGS)

print(ccpkg.root_dir)
print(ccpkg.project_dir)
print(dump(args))
