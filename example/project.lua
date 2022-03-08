return {
  tuplets={
    "x64-linux",
    "arm-android",
    "arm64-android", "x86-android", "x64-android"
  },
  android={
    ndk_home='/data/AndroidSdk/ndk/23.1.7779620',
    ndk_api=23
  },
  dependencies={
    "libffi",
    "spdlog",
    {
      name="msgpack-cxx",
      version="latest",
      configure_options={
        MSGPACK_CXX17="ON",
        MSGPACK_USE_BOOST="OFF",
      }
    }
  },
  export={
    {
      type='prefab',
      name='spdlog',
      modules={'spdlog', 'fmt'},
      min_sdk=23,
      target_sdk=31,
      maven=true,
    }
  }
}
