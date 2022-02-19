local BuildSystem = {}
BuildSystem.__index = BuildSystem

function BuildSystem:new(o)
  setmetatable(o, self)
  return o
end

function BuildSystem:execute(step, pkg)
end

function BuildSystem:configure(pkg)
  self.execute("configure", pkg)
end

function BuildSystem:build(pkg)
  self.execute("build", pkg)
end

function BuildSystem:install(pkg)
  self.execute("install", pkg)
end

return BuildSystem