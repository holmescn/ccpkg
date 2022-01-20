local Pkg = create_pkg {
  name="bzip2",
  versions={
    ["latest"]={
      url='https://www.sourceware.org/pub/bzip2/bzip2-latest.tar.gz',
      hash='sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269'
    },
    ['1.0.8']={
      url='https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz',
      hash='sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269'
    }
  }
}

function Pkg:install()
  local cmakelists = path.join {CCPKG_ROOT_DIR, "ports", "bzip2", "CMakeLists.txt"}
  assert(fs.copyfile(cmakelists, path.join {self.src_dir, "CMakeLists.txt"}), "copy file failed")

  self.data.build_dir = self.src_dir:gsub("-src$", "-build")
  if fs.exists(self.build_dir) then
    os.remove(self.build_dir)
  end
  fs.mkdirs(self.build_dir)
end

return Pkg