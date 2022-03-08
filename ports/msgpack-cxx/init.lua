---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local Pkg = require "ccpkg.pkg"
local MessagePack = Pkg:new {
  name="msgpack-cxx",
  description="MessagePack is an efficient binary serialization format, which lets you exchange data among multiple languages like JSON, except that it's faster and smaller.",
  homepage="https://github.com/msgpack/msgpack-c",
  url_pattern='https://github.com/msgpack/msgpack-c/releases/download/cpp-$version/msgpack-cxx-$version.tar.gz',
  versions={
    ["latest"]="4.1.0",
    ['4.1.0']={
      hash='sha256:11e042ffdafda6fc4ebdc5f4f63b352229b89796c2f8aa3e813116ec1dd8377d'
    }
  },
  patches={
    "0001-fix-no-boost.patch",
  },
  buildsystem="cmake"
}

function MessagePack:before_configure(opt)
  opt.options['MSGPACK_BUILD_DOCS'] = 'OFF'
  if self.machine == "arm" or self.machine == "x86" then
    opt.options['MSGPACK_32BIT'] = 'ON'
  end
end

function MessagePack:after_install(opt)
  if self.configure_options['MSGPACK_USE_BOOST'] == 'OFF' then
    local cmakelists = os.path.join(self.install_dir, 'lib', 'cmake', 'msgpackc-cxx', 'msgpack-config.cmake')
    ccpkg.edit(cmakelists, function(line)
      if line:match("^find_dependency.Boost") then
        return '# ' .. line
      end
      return line
    end)
  end
end

return MessagePack