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
  dirs.sysroot = os.path.join(root_dir, 'sysroot')
  dirs.packages = os.path.join(root_dir, 'packages')

  for _, dir in pairs(dirs) do
    if not os.path.exists(dir) then
      os.mkdirs(dir)
    end
  end

  return dirs
end

return ccpkg