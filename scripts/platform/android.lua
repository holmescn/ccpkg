local Platform = require "platform"
local Android = Platform:new {
  name="android",
  arch={
    ["arm"]={
      abi="armeabi-v7a",
      host='arm-none-linux-android',
      clang="armv7a-linux-androideabi%d-clang"
    },
    ['arm64']={
      abi="arm64-v8a",
      host='arm64-none-linux-android',
      clang="aarch64-linux-android%d-clang"
    },
    ["x86"]={
      abi='x86',
      host='x86-none-linux-android',
      clang="i686-linux-android%d-clang"
    },
    ['x64']={
      abi='x86_64',
      host='x64-none-linux-android',
      clang="x86_64-linux-android%d-clang"
    }
  }
}

function Android:init(project)
  self.ndk_home = project.android.ndk_home
  self.toolchain_file = os.path.join(self.ndk_home, "build", "cmake", "android.toolchain.cmake")
  self:detect_ndk_version()

  local default_native_api_level = 23
  self.api_level = project.android.native_api_level or default_native_api_level
  self.android_stl = project.android_stl or "c++_shared"
  self.android_ld = project.android_ld or "lld"

  self.llvm_path = os.path.join(self.ndk_home, 'toolchains', 'llvm', 'prebuilt')
  for _, dir in ipairs(os.listdir(self.llvm_path)) do
    self.llvm_path = os.path.join(self.llvm_path, dir)
    break
  end
  return self
end

function Android:detect_ndk_version()
  local source_properties = os.path.join(self.ndk_home, "source.properties")
  for line in io.lines(source_properties) do
    local _1, _2, _3 = line:match("^Pkg%.Revision%s*=%s*(%d+)%.(%d+)%.(%d+)")
    if _1 then
      self.ndk_version_major = tonumber(_1)
      self.ndk_version_major = tonumber(_2)
      self.ndk_version_major = tonumber(_3)
      self.ndk_version_beta = line:match("-beta(%d+)$")
      self.ndk_version_beta = tonumber(self.ndk_version_beta)
    end
  end
end

function Android:execute(step, pkg)
  self[pkg.buildsystem.name](self, step, pkg)
end

function Android:cmake(opt)
  opt.options = opt.options or {}
  opt.options["ANDROID_LD"] = self.android_ld
  opt.options["ANDROID_STL"] = self.android_stl
  opt.options["ANDROID_ABI"] = self[opt.arch].abi
  opt.options["ANDROID_PLATFORM"] = ("android-%d"):format(self.api_level)
  opt.options["CMAKE_TOOLCHAIN_FILE"] = self.toolchain_file
end

function Android:configure_make(opt)
  opt.envs = opt.envs or {}
  opt.envs["CC"] = self[opt.arch].clang:format(self.api_level)
  opt.envs["CXX"] = self[opt.arch].clang:format(self.api_level) .. '++'
  opt.envs["AR"] = "llvm-ar"
  opt.envs["AS"] = "llvm-as"
  opt.envs["LD"] = "ld.lld"
  opt.envs["NM"] = "llvm-nm"
  opt.envs["OBJDUMP"] = "llvm-objdump"
  opt.envs["RANLIB"] = "llvm-ranlib"
  opt.envs["READELF"] = "llvm-readelf"
  opt.envs["STRIP"] = "llvm-strip"
  table.insert(opt.args, "--host")
  table.insert(opt.args, self[opt.arch].host)
end

return Android