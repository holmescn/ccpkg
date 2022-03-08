---@diagnostic disable: undefined-global
local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "A better vcpkg.")
  :command_target("command")

local default_project_file = os.path.join(".", "project.lua")
parser:option "-c" "--project_file"
  :description "Specify the project file."
  :default (default_project_file)

parser.commands = {}
require("cli.install"):init(parser)
require("cli.export"):init(parser)

local args = parser:parse(ARGS)
-- parser.commands[args.command]:execute(args)

-- Run with stack trace
xpcall(parser.commands[args.command]['execute'], function(msg)
  print(debug.traceback())
  print(msg)
end, parser.commands[args.command], args)