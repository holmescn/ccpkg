local ccpkg = require "ccpkg"
local PyBind11 = ccpkg.create_pkg {
  name="pybind11",
  description="pybind11 is a lightweight header-only library that exposes C++ types in Python and vice versa, mainly to create Python bindings of existing C++ code",
  homepage="https://github.com/pybind/pybind11",
  url_pattern='https://github.com/pybind/pybind11/archive/refs/tags/v$version.tar.gz',
  filename="pybind11-$version.tar.gz",
  versions={
    ["latest"]="2.9.1",
    ['2.9.1']={
      hash='sha256:c6160321dc98e6e1184cc791fbeadd2907bb4a0ce0e447f2ea4ff8ab56550913'
    }
  },
  features={
    draft={
      description="Build and install draft",
      configure_options={
        ENABLE_DRAFTS='ON'
      }
    }
  },
  buildsystem="cmake"
}

return PyBind11