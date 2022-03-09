local ccpkg = require "ccpkg"
local RapidJSON = ccpkg.create_pkg {
  name="rapidjson",
  description="A fast JSON parser/generator for C++ with both SAX/DOM style API.",
  homepage="http://rapidjson.org/",
  url_pattern='https://github.com/Tencent/rapidjson/archive/refs/tags/v$version.tar.gz',
  filename="rapidjson-$version.tar.gz",
  versions={
    ["latest"]="1.1.0",
    ['1.1.0']={
      hash='sha256:bf7ced29704a1e696fbccf2a2b4ea068e7774fa37f6d7dd4039d0787f8bed98e'
    }
  },
  buildsystem="cmake",
  patches={
    '0001-add-prefix-to-pkgconfig.patch'
  }
}

function RapidJSON:before_configure(opt)
  opt.options['RAPIDJSON_BUILD_DOC'] = 'OFF'
  opt.options['RAPIDJSON_BUILD_EXAMPLES'] = 'OFF'
  opt.options['RAPIDJSON_BUILD_TESTS'] = 'OFF'
  opt.options['RAPIDJSON_HAS_STDSTRING'] = 'ON'
end

return RapidJSON
