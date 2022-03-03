---@diagnostic disable: undefined-field
local Args = require "ccpkg.args"
local Platform = require "platform"
local Linux = Platform:new {
  name="linux",
  data={
    ['arm']={
      host='arm-unknown-linux-gnueabihf',
      processor='armeabi-v7a',
    },
    ['arm64']={
      host='aarch64-pc-linux-gnu',
      processor='arm64-v8a',
    },
    ['x86']={
      host='i686-pc-linux-gnu',
      processor='x86',
    },
    ['x64']={
      host='x86_64-pc-linux-gnu',
      processor='x86_64',
    },
  }
}

function Linux:init(project)
  return self
end

function Linux:execute(step, pkg, opt)
  self[pkg.buildsystem.name](self, step, pkg, opt)
end

function Linux:cmake(step, pkg, opt)
  if step == "configure" then
    opt.options['CMAKE_SYSTEM_NAME'] = 'Linux'
    opt.options['CMAKE_SYSTEM_PROCESSOR'] = self.data[pkg.machine].processor
  end
end

function Linux:configure_make(step, pkg, opt)
  if step == "configure" then
    opt.args:append('--host=' .. self.data[pkg.machine].host)
  end
end

return Linux