---@diagnostic disable: undefined-field
local Args = require "ccpkg.args"
local Platform = require "platform"
local Android = Platform:new {
  name="android",
  data={
    ["arm"]={
      abi="armeabi-v7a",
      host='arm-unknown-linux-android',
      library_arch='arm-linux-androideabi',
      clang="armv7a-linux-androideabi%d-clang"
    },
    ['arm64']={
      abi="arm64-v8a",
      host='arm64-unknown-linux-android',
      library_arch='aarch64-linux-android',
      clang="aarch64-linux-android%d-clang"
    },
    ["x86"]={
      abi='x86',
      host='i686-unknown-linux-android',
      library_arch='i686-linux-android',
      clang="i686-linux-android%d-clang"
    },
    ['x64']={
      abi='x86_64',
      host='x86_64-unknown-linux-android',
      library_arch='x86_64-linux-android',
      clang="x86_64-linux-android%d-clang"
    }
  }
}

function Android:init(project)
  if self.initialized then return self end

  self.ndk_home = project.android.ndk_home
  self.toolchain_file = os.path.join(self.ndk_home, "build", "cmake", "android.toolchain.cmake")
  self:detect_ndk_version()

  self.android_ld = project.android_ld or "lld"
  self.android_stl = project.android_stl or "c++_shared"

  local default_ndk_api = 16
  self.ndk_api = project.android.ndk_api or default_ndk_api

  self.llvm_path = os.path.join(self.ndk_home, 'toolchains', 'llvm', 'prebuilt')
  for dir in os.listdir(self.llvm_path) do
    self.llvm_path = os.path.join(self.llvm_path, dir)
    break
  end

  self.initialized = true
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

function Android:execute(step, pkg, opt)
  self[pkg.buildsystem.name](self, step, pkg, opt)
end

function Android:cmake(step, pkg, opt)
  if step == "configure" then
    -- opt.options['ANDROID_LD'] = self.android_ld
    opt.options['ANDROID_STL'] = self.android_stl
    opt.options['ANDROID_ABI'] = self.data[pkg.machine].abi
    opt.options['ANDROID_PLATFORM'] = 'android-' .. self.ndk_api
    opt.options['CMAKE_TOOLCHAIN_FILE'] = self.toolchain_file
  end
end

function Android:configure_make(step, pkg, opt)
  if step == "configure" then
    opt.env["CC"] = self.data[pkg.machine].clang:format(self.ndk_api)
    opt.env["CXX"] = opt.env['CC'] .. '++'
    opt.env["AR"] = "llvm-ar"
    opt.env["AS"] = "llvm-as"
    opt.env["LD"] = "ld.lld"
    opt.env["NM"] = "llvm-nm"
    opt.env["STRIP"] = "llvm-strip"
    opt.env["RANLIB"] = "llvm-ranlib"
    opt.env["OBJDUMP"] = "llvm-objdump"
    opt.env["READELF"] = "llvm-readelf"
    opt.args:add("--host=" .. self.data[pkg.machine].host)
  end
  table.insert(opt.env["PATH"], 1, os.path.join(self.llvm_path, "bin"))
end

return Android
