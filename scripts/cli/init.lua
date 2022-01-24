local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "An better vcpkg.")

-- install dependencies described in project.lua
parser:command("install")

local function execute_cmd(name)
  local cmd = require("cli." .. name)
  cmd(args)
end

local args = parser:parse(ARGS)

if args.install then
  execute_cmd("install")
end
