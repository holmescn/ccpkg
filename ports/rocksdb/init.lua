local ccpkg = require "ccpkg"
local RocksDB = ccpkg.create_pkg {
  name="rocksdb",
  description="A library that provides an embeddable, persistent key-value store for fast storage",
  homepage="https://github.com/facebook/rocksdb",
  url_pattern='https://github.com/facebook/rocksdb/archive/refs/tags/v$version.tar.gz',
  filename="rocksdb-$version.tar.gz",
  versions={
    ["latest"]="6.29.3",
    ['6.29.3']={
      hash='sha256:724e4cba2db6668ff6a21ecabcce0782cd0c8e386796e7e9a14a8260e0600abd'
    }
  },
  patches={
    android={
      '0001-fix-android.patch'
    }
  },
  buildsystem="cmake"
}

return RocksDB