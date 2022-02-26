local Pkg = require "ccpkg.pkg"
local LibZmq = Pkg:new {
  name="libzmq",
  description="The ZeroMQ lightweight messaging kernel is a library which extends the standard socket interfaces with features traditionally provided by specialised messaging middleware products",
  homepage="https://github.com/zeromq/libzmq",
  url_pattern='https://github.com/zeromq/libzmq/releases/download/v$version/zeromq-$version.tar.gz',
  license="LGPL-3.0-only",
  versions={
    ["latest"]="4.3.4",
    ['4.3.4']={
      hash='sha256:540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620'
    }
  },
  buildsystem="configure_make"
}

return LibZmq