local Pkg = require "ccpkg.pkg"
local CppZmq = Pkg:new {
  name="cppzmq",
  description="lightweight messaging kernel, C++ bindings.",
  homepage="https://github.com/zeromq/cppzmq",
  url_pattern='https://github.com/zeromq/cppzmq/archive/refs/tags/v$version.tar.gz',
  filename="cppzmq-$version.tar.gz",
  versions={
    ["latest"]="4.8.1",
    ['4.8.1']={
      hash='sha256:7a23639a45f3a0049e11a188e29aaedd10b2f4845f0000cf3e22d6774ebde0af'
    }
  },
  buildsystem="cmake"
}

function CppZmq:dependencies()
  return {
    libzmq='latest'
  }
end

return CppZmq