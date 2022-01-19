-- keep for debug
function debug_dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. debug_dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function create_working_dirs(root)
   if not fs.exists(root) then
      fs.mkdirs(root)
   end

   local dirs = {'tmp', 'downloads', 'installed'}
   for _, d in ipairs(dirs) do
      local p = path_join(root, d)
      if not fs.exists(p) then
         fs.mkdirs(p)
      end
   end
end

-- extend package path to include scripts in CCPKG_ROOT_DIR
package.path = './?/init.lua;./?.lua'
package.path = path_join(CCPKG_ROOT_DIR, 'scripts', "?.lua;") .. package.path
package.path = path_join(CCPKG_ROOT_DIR, 'scripts', '?', "init.lua;") .. package.path
package.path = path_join(CCPKG_ROOT_DIR, 'ports', "?.lua;") .. package.path
package.path = path_join(CCPKG_ROOT_DIR, 'ports', '?', "init.lua;") .. package.path
package.cpath = ''

-- check project.lua
local cfg_file = path_join(PROJECT_DIR, 'project.lua')
if not fs.exists(cfg_file) then
   print(string.format("%s isn't a project directory", PROJECT_DIR))
   return
end

local project_cfg = dofile(cfg_file)

-- create working dirs
create_working_dirs(path_join(PROJECT_DIR, ".ccpkg"))

local argparse = require('3rdparty.argparse')
local parser = argparse("ccpkg", "An example.")

-- install dependencies described in project.lua
parser:command("install")

local args = parser:parse(ARGS)

if args.install then
   local cmd = require('commands.install')
   cmd(project_cfg)
end
