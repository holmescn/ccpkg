local Platform = {}
local ABI = {
  ["arm"]="armeabi-v7a",
  ["arm64"]="arm64-v8a",
  ["x86"]="x86",
  ["x64"]="x86_64"
}

function Platform:toolchain_file(toolchain_file)
  assert(ccpkg.target.ndk_home, "no ndk_home field")

  local ndk_home = ccpkg.target.ndk_home
  local native_api_level = ccpkg.target.native_api_level or 23

  -- ANDROID_STL c++_shared c++_static
  toolchain_file:write(("set(ANDROID_STL \"%s\")"):format("c++_shared"), "\n")
  toolchain_file:write(("set(ANDROID_LD \"%s\")"):format("lld"), "\n")
  toolchain_file:write(("set(ANDROID_PLATFORM \"android-%s\")"):format(native_api_level), "\n")

  local android_toolchain_file = os.path.join {ndk_home, "build", "cmake", "android.toolchain.cmake"}
  toolchain_file:write(("include(\"%s\")"):format(android_toolchain_file), "\n")
end

function Platform:cmake(pkg, options)
  table.insert(options.args, 1, "--toolchain")
  table.insert(options.args, 2, ccpkg.toolchain_file)
  table.insert(options.args, 3, ("-DANDROID_ABI=%s"):format(ABI[options.arch]))
end

return Platform