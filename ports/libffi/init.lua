local Pkg = {
  name="libffi",
  description="Portable, high level programming interface to various calling conventions",
  homepage="https://github.com/libffi/libffi",
  versions={
    ["latest"]="3.4.2",
    ['3.4.2']={
      url='https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz',
      hash='sha256:540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620'
    }
  },
  buildsystem="configure_make"
}

return Pkg
