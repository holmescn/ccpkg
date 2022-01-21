return {
  name="example-ccpkg-project",
  version="1.0",
  description="example ccpkg project",
  target={
    platform='android',
    arch={'arm', 'arm64', 'x86', 'x64'},
    ndk_home='/data/AndroidSdk/ndk/23.1.7779620',
    native_api_level=23
  },
  dependencies={
    bzip2={
      version='1.0.8'
    }
  }
}
