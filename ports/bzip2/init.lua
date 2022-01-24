local Pkg = {
  name="bzip2",
  description="bzip2 is a freely available, patent free, high-quality data compressor. It typically compresses files to within 10% to 15% of the best available techniques (the PPM family of statistical compressors), whilst being around twice as fast at compression and six times faster at decompression.",
  homepage="https://sourceware.org/bzip2/",
  documentation="https://sourceware.org/bzip2/docs.html",
  versions={
    ["latest"]={
      url='https://www.sourceware.org/pub/bzip2/bzip2-latest.tar.gz',
      hash='sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269',
      extract_name='bzip2-1.0.8'
    },
    ['1.0.8']={
      url='https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz',
      hash='sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269'
    }
  },
  buildsystem="cmake"
}

function Pkg:before_configuration(ccpkg, opt)
  local cmakelists = os.path.join {ccpkg.root_dir, "ports", "bzip2", "CMakeLists.txt"}
  os.copyfile(cmakelists, os.path.join {opt.src_dir, "CMakeLists.txt"}, {skip=1})
end

return Pkg
