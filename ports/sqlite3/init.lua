local Pkg = {
  name="sqlite3",
  description="SQLite is a software library that implements a self-contained, serverless, zero-configuration, transactional SQL database engine.",
  homepage="https://sqlite.org/",
  versions={
    ["latest"]="3.37.0",
    ['3.37.0']={
      url='https://www.sqlite.org/2022/sqlite-autoconf-3370200.tar.gz',
      hash='sha256:4089a8d9b467537b3f246f217b84cd76e00b1d1a971fe5aca1e30e230e46b2d8',
    }
  },
  buildsystem="configure_make"
}

return Pkg
