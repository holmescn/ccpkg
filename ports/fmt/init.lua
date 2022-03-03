local Pkg = require "ccpkg.pkg"
local Fmt = Pkg:new {
  name="fmt",
  description="Formatting library for C++. It can be used as a safe alternative to printf or as a fast alternative to IOStreams.",
  homepage="https://github.com/fmtlib/fmt",
  url_pattern='https://github.com/fmtlib/fmt/archive/refs/tags/$version.tar.gz',
  filename="fmt-$version.tar.gz",
  versions={
    ["latest"]="8.1.1",
    ['8.1.1']={
      hash='sha256:3d794d3cf67633b34b2771eb9f073bde87e846e0d395d254df7b211ef1ec7346'
    }
  },
  buildsystem="cmake"
}

return Fmt