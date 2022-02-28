local ccpkg = require "ccpkg"
local Pkg = require "ccpkg.pkg"
local BZip2 = Pkg:new {
  name="bzip2",
  description="bzip2 is a freely available, patent free, high-quality data compressor. It typically compresses files to within 10% to 15% of the best available techniques (the PPM family of statistical compressors), whilst being around twice as fast at compression and six times faster at decompression.",
  homepage="https://sourceware.org/bzip2/",
  documentation="https://sourceware.org/bzip2/docs.html",
  url_pattern="https://www.sourceware.org/pub/bzip2/bzip2-$version.tar.gz",
  versions={
    ["latest"]="1.0.8",
    ['1.0.8']={
      hash='sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269'
    }
  },
  buildsystem="cmake"
}

function BZip2:patch_source()
  local src = os.path.join(ccpkg.ports_dir, "bzip2", "CMakeLists.txt")
  local dst = os.path.join(self.src_dir, "CMakeLists.txt")
  os.copy_file(src, dst, {override=1})
end

return BZip2
