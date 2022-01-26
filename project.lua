return {
  target={
    platform='android',
    arch={'arm', 'arm64', 'x86', 'x64'},
    ndk_home='/data/AndroidSdk/ndk/23.1.7779620',
    native_api_level=23
  },
  dependencies={
    bzip2={
      version='1.0.8'
    },
    libffi={
      version='latest'
    },
    liblzma={
      version='latest'
    },
    sqlite3={
      version='latest'
    },
    openssl={
      version='latest'
    },
  }
}
