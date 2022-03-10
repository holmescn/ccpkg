---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local Lz4 = ccpkg.create_pkg {
  name="lz4",
  description="Lossless compression algorithm, providing compression speed at 400 MB/s per core.",
  homepage="https://github.com/lz4/lz4",
  url_pattern="https://github.com/lz4/lz4/archive/refs/tags/v$version.tar.gz",
  filename="lz4-$version.tar.gz",
  versions={
    ["latest"]="1.9.3",
    ['1.9.3']={
      hash='sha256:030644df4611007ff7dc962d981f390361e6c97a34e5cbc393ddfbe019ffe2c1'
    }
  },
  buildsystem="cmake"
}

function Lz4:patch_source()
  local src = os.path.join(ccpkg.ports_dir, self.name, "CMakeLists.txt")
  local dst = os.path.join(self.src_dir, "CMakeLists.txt")
  os.copy_file(src, dst, {override=1})
end

return Lz4