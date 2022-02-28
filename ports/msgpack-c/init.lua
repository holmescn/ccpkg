local Pkg = require "ccpkg.pkg"
local MessagePack = Pkg:new {
  name="msgpack-c",
  description="MessagePack is an efficient binary serialization format, which lets you exchange data among multiple languages like JSON, except that it's faster and smaller.",
  homepage="https://github.com/msgpack/msgpack-c",
  url_pattern='https://github.com/msgpack/msgpack-c/releases/download/c-$version/msgpack-c-$version.tar.gz',
  versions={
    ["latest"]="4.0.0",
    ['4.0.0']={
      hash='sha256:420fe35e7572f2a168d17e660ef981a589c9cbe77faa25eb34a520e1fcc032c8'
    }
  },
  buildsystem="cmake"
}

function MessagePack:before_configure(opt)
  opt.args:append("-DCMAKE_INSTALL_PREFIX=" .. self.install_dir)
end

return MessagePack