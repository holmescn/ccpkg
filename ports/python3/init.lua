local Pkg = require "ccpkg.pkg"
local Python3 = Pkg:new {
  name="python3",
  description="The Python programming language",
  homepage="https://github.com/python/cpython",
  url_pattern='https://www.python.org/ftp/python/$version/Python-$version.tar.xz',
  versions={
    ["latest"]="3.10.2",
    ['3.10.2']={
      hash='sha256:17de3ac7da9f2519aa9d64378c603a73a0e9ad58dffa8812e45160c086de64c7'
    }
  },
  patches={
    android={
      '0001-fix-android-cross-compiling-standard-libraries.patch'
    }
  },
  buildsystem="configure_make"
}

function Python3:dependencies()
  return {
    "bzip2", "expat",
    "libffi", "liblzma", "libuuid",
    "sqlite3", "openssl",
  }
end

function Python3:before_configure(opt)
  opt['_args']:append("--build=x86_64-pc-linux-gnux32")
  opt['_args']:append("--enable-shared")
  opt['_args']:append("--disable-ipv6")
  opt['_args']:append("CFLAGS=-I" .. os.path.join(self.install_dir, 'include'))
  opt['_args']:append("CONFIG_SITE=" .. os.path.join(self.build_dir, 'config.site'))
  opt.args[3] = table.concat(opt['_args'], " ")

  local config_site_file = io.open(os.path.join(self.build_dir, "config.site"), "w+")
  config_site_file:write("ac_cv_file__dev_ptc=no\n")
  config_site_file:write("ac_cv_file__dev_ptmx=no")
  config_site_file:close()
end

function Python3:before_build(opt)
  local makefile_path = os.path.join(self.build_dir, "Makefile")
  local lines = {}
  for line in io.lines(makefile_path) do
    if line:match("^OPT%s*=") then
      table.insert(lines, line .. ' -fPIC -DPIC')
    else
      table.insert(lines, line)
    end
  end

  local makefile_file = io.open(makefile_path, "w+")
  makefile_file:write(table.concat(lines, '\n'))
  makefile_file:close()
end

return Python3