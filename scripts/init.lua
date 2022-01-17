-- keep for debug
local function dump(o)
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

-- extend package path to include scripts in CCPKG_ROOT_DIR
package.path = os.path_join(CCPKG_ROOT_DIR, 'scripts', "?.lua;") .. package.path
package.path = os.path_join(CCPKG_ROOT_DIR, 'scripts', '?', "init.lua;") .. package.path
package.cpath = ''

local argparse = require('3rdparty.argparse')
local parser = argparse("ccpkg", "An example.")

-- init command create a project.lua in current dir
parser:command("init")

-- install dependencies described in project.lua
parser:command("install")

local args = parser:parse(ARGS)

print("current dir", fs.currentdir())
print("root dir", CCPKG_ROOT_DIR)
print(dump(args))

local dotccpkg = os.path_join(fs.currentdir(), ".ccpkg")
fs.mkdirs(dotccpkg)
if fs.exists(dotccpkg) then
   print(string.format("%s is created", dotccpkg))
end

print(os.name)
