local Pkg = require "ccpkg.pkg"
local LibFfi = Pkg:new {
  name="libffi",
  description="Portable, high level programming interface to various calling conventions",
  homepage="https://github.com/libffi/libffi",
  url_pattern='https://github.com/libffi/libffi/releases/download/v$version/libffi-$version.tar.gz',
  versions={
    ["latest"]="3.4.2",
    ['3.4.2']={
      hash='sha256:540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620'
    }
  },
  buildsystem="configure_make"
}

return LibFfi
