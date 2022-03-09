local ccpkg = require "ccpkg"
local LibLzma = ccpkg.create_pkg {
  name="liblzma",
  description="Compression library with an API similar to that of zlib.",
  homepage="hhttps://github.com/xz-mirror/xz",
  url_pattern='https://github.com/xz-mirror/xz/releases/download/v$version/xz-$version.tar.bz2',
  versions={
    ["latest"]="5.2.2",
    ['5.2.2']={
      hash='sha256:6ff5f57a4b9167155e35e6da8b529de69270efb2b4cf3fbabf41a4ee793840b5'
    }
  },
  buildsystem="configure_make"
}

return LibLzma
