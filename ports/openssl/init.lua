local Args = require "ccpkg.args"
local Pkg = require "ccpkg.pkg"
local OpenSSL = Pkg:new {
  name="openssl",
  description="OpenSSL is an open source project that provides a robust, commercial-grade, and full-featured toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols. It is also a general-purpose cryptography library.",
  homepage="https://www.openssl.org",
  url_pattern='https://www.openssl.org/source/openssl-$version.tar.gz',
  versions={
    ["latest"]="1.1.1m",
    ['1.1.1m']={
      hash='sha256:f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96'
    }
  },
  buildsystem="configure_make"
}

function OpenSSL:before_configure(opt)
  local perl_path = os.which("perl")
  if self.platform.name == "android" then
    -- use perl instead of sh
    opt['_args'][1] = opt['_args'][1]:gsub("configure", "Configure")
    for i, v in ipairs(opt['_args']) do
      if v:match("^--host=") then
        table.remove(opt['_args'], i)
        break
      end
    end
    opt['_args']:append("-D__ANDROID_API__=" .. self.platform.native_api_level)

    local arch_map = {
      arm='android-arm',
      arm64='android-arm64',
      x86='android-x86',
      x64='android-x86_64',
    }
    if arch_map[self.machine] then
      opt['_args']:append(arch_map[self.machine])
    else
      error("unsupported android arch: " .. self.machine)
    end

    opt.args = Args:new {perl_path}
    opt.args:extend(opt['_args'])
  end
end

return OpenSSL
