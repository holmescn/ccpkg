local ccpkg = require "ccpkg"
local Expat = ccpkg.create_pkg {
  name="expat",
  description="XML parser library written in C",
  homepage="https://github.com/libexpat/libexpat",
  versions={
    ["latest"]="2.4.4",
    ['2.4.4']={
      url='https://github.com/libexpat/libexpat/releases/download/R_2_4_4/expat-2.4.4.tar.bz2',
      hash='sha256:14c58c2a0b5b8b31836514dfab41bd191836db7aa7b84ae5c47bc0327a20d64a'
    }
  },
  buildsystem="configure_make"
}

return Expat
