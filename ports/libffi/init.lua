local Pkg = create_pkg {
  name="libffi",
  description="Portable, high level programming interface to various calling conventions",
  homepage="https://github.com/libffi/libffi",
  versions={
    ["latest"]={
      url='https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz',
      hash='sha256:540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620',
      extract_name='libffi-3.4.2'
    },
    ['3.4.2']={
      url='https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz',
      hash='sha256:540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620'
    }
  }
}

function Pkg:script(arch)
  ccpkg:configure_make (self, {
    arch=arch
  })
end

return Pkg