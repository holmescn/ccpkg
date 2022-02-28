---@diagnostic disable: undefined-field
local root_dir = os.getenv("CCPKG_ROOT")
local ccpkg = {
  root_dir=root_dir,
  ports_dir=os.path.join(root_dir, "ports"),
  scripts_dir=os.path.join(root_dir, "scripts"),
}

function ccpkg:makedirs(project_dir)
  local dirs = {project_dir=project_dir}
  local root_dir = os.path.join(project_dir, ".ccpkg")
  if not os.path.exists(root_dir) then
     os.mkdirs(root_dir)
  end
  dirs['.ccpkg'] = root_dir

  dirs.tmp = os.path.join(root_dir, 'tmp')
  dirs.downloads = os.path.join(root_dir, 'downloads')
  dirs.installed = os.path.join(root_dir, 'installed')
  dirs.packages = os.path.join(root_dir, 'packages')

  for _, dir in pairs(dirs) do
    if not os.path.exists(dir) then
      os.mkdirs(dir)
    end
  end

  return dirs
end

function ccpkg.edit(filename, f)
  local lines = {}
  for line in io.lines(filename) do
    local x = f(line)
    table.insert(lines, x)
  end
  local fp = io.open(filename, 'w+')
  fp:write(table.concat(lines, '\n'))
  fp:close()
end

return ccpkg