local Pkg = {
  name="liblzma",
  description="Compression library with an API similar to that of zlib.",
  homepage="hhttps://github.com/xz-mirror/xz",
  versions={
    ["latest"]="5.2.2",
    ['5.2.2']={
      url='https://github.com/xz-mirror/xz/releases/download/v5.2.2/xz-5.2.2.tar.gz',
      hash='sha256:73df4d5d34f0468bd57d09f2d8af363e95ed6cc3a4a86129d2f2c366259902a2'
    }
  },
  buildsystem="configure_make"
}

return Pkg
