return {
  tuplets={
    "x64-linux"
    -- "arm-android",
    -- "arm64-android",
    -- "x86-android", "x64-android"
  },
  android={
    ndk_home='/data/AndroidSdk/ndk/23.1.7779620',
    ndk_api=23
  },
  dependencies={
    "spdlog", "libffi",
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
