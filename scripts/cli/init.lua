local argparse = require '3rdparty.argparse'
local parser = argparse("ccpkg", "A better vcpkg.")
  :command_target("command")

parser:flag("-v --verbose", "Sets verbosity level.")
  :count "0-2"
  :target "verbosity"

local install_cmd = parser:command("install i", "Install the project")
install_cmd:option "-c" "--project_file"
  :description "Specify the project file."
  :default "project.lua"

local args = parser:parse(ARGS)

local cmd = require("cli." .. args.command)
cmd(args)