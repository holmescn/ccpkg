---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local Command = {}

function Command:init(parser)
  local cmd = parser:command("export e", "Export packages")
  parser.commands['export'] = self

  self.prefab = require("cli.export.prefab"):init(parser)
end

function Command:execute(args)
  local project_file = os.path.realpath(args.project_file)
  local project_dir = os.path.dirname(project_file)
  print("--- project dir  " .. project_dir)
  print("--- project file " .. project_file)

  local project = dofile(project_file)
  project.dirs = ccpkg:makedirs(project_dir)
  project.args = args

  for spec in table.each(project.export) do
    self[spec.type]:execute(project, spec)
  end
end

return Command