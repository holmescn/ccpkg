local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "An example.")

-- install dependencies described in project.lua
parser:command("install")

local args = parser:parse(ARGS)

if args.install then
  ccpkg:load 'project.lua'
  ccpkg:install(args)
end
