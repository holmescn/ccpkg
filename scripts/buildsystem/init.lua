---@diagnostic disable: undefined-field
local BuildSystem = {
}
BuildSystem.__index = BuildSystem

function BuildSystem:new(o)
  setmetatable(o, self)
  return o
end

function BuildSystem:execute(step, pkg, opt)
  local log_file = os.path.join(pkg.build_base_dir, ("%s-%s.log"):format(
    (step == "configure" and "config" or step),
    pkg.tuplet
  ))
  if not opt.capture_output then
    opt.file = opt.file or log_file
  end
  opt.cwd = opt.cwd or pkg.build_dir
  return os.run(opt.args, opt)
end

function BuildSystem:execute_hook(prefix, step, pkg, opt)
  local name = prefix .. "_" .. step
  if self[name] then
    self[name](self, pkg, opt)
  end
end

return BuildSystem