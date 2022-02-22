local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "A better vcpkg.")
  :command_target("command")

print(table.dump(parser))

require("cli.install"):init(parser)

local args = parser:parse(ARGS)
parser.commands[args.command]:execute(args)