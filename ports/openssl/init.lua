---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local buildsystem = require "buildsystem"
local Args = require "ccpkg.args"
local OpenSSL = ccpkg.create_pkg {
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

function OpenSSL:configure(opt)
  local perl_path = os.which("perl")
  -- use perl instead of sh
  local args = Args:new {perl_path}
  local configure_script = opt.args[1]:gsub("configure", "Configure")
  args:append(configure_script)
  args:append('--prefix=' .. self.install_dir)

  if self.platform.name == "android" then
    args:append("-D__ANDROID_API__=" .. self.platform.ndk_api)
    local arch_map = {
      arm='android-arm',
      arm64='android-arm64',
      x86='android-x86',
      x64='android-x86_64',
    }
    if arch_map[self.machine] then
      args:append(arch_map[self.machine])
    else
      error("unsupported android arch: " .. self.machine)
    end
  end
  opt.args = args
  buildsystem:execute('configure', self, opt)
end

return OpenSSL
