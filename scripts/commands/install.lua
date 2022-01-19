return function (project)
  print("install")
  print("project dir", PROJECT_DIR)
  print("os name ", os.name)
  print("platform", project.platform)

  local platform = require('platform.' .. project.platform)

  local cfg = {}
  for k, v in pairs(project) do
    if k ~= "dependencies" then
      cfg[k] = v
    end
  end

  for k, v in pairs(project.dependencies) do
    local pkg = require(k)
    pkg.install(cfg, v)
  end
end