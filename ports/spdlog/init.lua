local ccpkg = require "ccpkg"
local SpdLog = ccpkg.create_pkg {
  name="spdlog",
  description="Very fast, header only, C++ logging library",
  homepage="https://github.com/gabime/spdlog",
  license='MIT',
  url_pattern='https://github.com/gabime/spdlog/archive/refs/tags/v$version.tar.gz',
  filename="spdlog-$version.tar.gz",
  versions={
    ["latest"]="1.9.2",
    ['1.9.2']={
      hash='sha256:6fff9215f5cb81760be4cc16d033526d1080427d236e86d70bb02994f85e3d38'
    }
  },
  buildsystem="cmake"
}

function SpdLog:dependencies()
  return { 'fmt' }
end

return SpdLog
