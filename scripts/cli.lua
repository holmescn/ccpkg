local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "An better vcpkg.")

-- install dependencies described in project.lua
parser:command("install")

local args = parser:parse(ARGS)

if args.install then
  ccpkg:init 'project.lua'
  ccpkg:install(args)
end
