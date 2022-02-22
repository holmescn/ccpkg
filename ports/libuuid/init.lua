local Pkg = require "ccpkg.pkg"
local LibUUid = Pkg:new {
  name="libuuid",
  description="Universally unique id library",
  homepage="https://sourceforge.net/projects/libuuid",
  url_pattern='https://sourceforge.net/projects/libuuid/files/libuuid-$version.tar.gz',
  versions={
    ["latest"]="1.0.3",
    ['1.0.3']={
      hash='sha256:46af3275291091009ad7f1b899de3d0cea0252737550e7919d17237997db5644'
    }
  },
  buildsystem="configure_make"
}

return LibUUid