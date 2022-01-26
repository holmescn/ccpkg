local Pkg = {
  name="openssl",
  description="OpenSSL is an open source project that provides a robust, commercial-grade, and full-featured toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols. It is also a general-purpose cryptography library.",
  homepage="https://www.openssl.org",
  versions={
    ["latest"]="1.1.1m",
    ['1.1.1m']={
      url='https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1m.tar.gz',
      hash='sha256:36ae24ad7cf0a824d0b76ac08861262e47ec541e5d0f20e6d94bab90b2dab360'
    }
  },
  buildsystem="configure_make"
}

function Pkg:patch_source(ccpkg, opt)
  local old_file = os.path.join(opt.src_dir, "Configure")
  local new_file = os.path.join(opt.src_dir, "configure")
  os.rename(old_file, new_file)
end

function Pkg:before_configure(ccpkg, opt)
  if ccpkg.project.target.platform == "android" then
    for i, v in ipairs(opt.args) do
      if v == "--host" then
        opt.args[i] = ""
      elseif v == "arm-none-linux-android" then
        opt.args[i] = "android-arm"
      elseif v == "arm64-none-linux-android" then
        opt.args[i] = "android-arm64"
      elseif v == "x86-none-linux-android" then
        opt.args[i] = "android-x86"
      elseif v == "x64-none-linux-android" then
        opt.args[i] = "android-x86_64"
      end
    end
    table.insert(opt.envs, "ANDROID_NDK_HOME=" .. ccpkg.platform.ndk_home)
  end
end

return Pkg