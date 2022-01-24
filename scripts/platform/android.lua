local ccpkg = require "ccpkg"
local Platform = { default_native_api_level=23 }
local ABI = {
  ["arm"]="armeabi-v7a",
  ["arm64"]="arm64-v8a",
  ["x86"]="x86",
  ["x64"]="x86_64"
}

function Platform:cmake(opt)
  local ndk_home = ccpkg.project.target.ndk_home
  local api_level = ccpkg.project.target.native_api_level or self.default_native_api_level
  opt.options["ANDROID_LD"] = "lld"
  opt.options["ANDROID_STL"] = "c++_shared"
  opt.options["ANDROID_ABI"] = ABI[opt.arch]
  opt.options["ANDROID_PLATFORM"] = ("android-%d"):format(api_level)
  opt.options["CMAKE_TOOLCHAIN_FILE"] = os.path.join(ndk_home, "build", "cmake", "android.toolchain.cmake")
end

return Platform