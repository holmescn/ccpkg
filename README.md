# DESIGN

## `ccpkg install` command

1. load `project.lua` file and do init
2. build dependency tree
  1. check pkg port exists
  2. check pkg version exists
  3. check pkg version conflict
  4. sort the dependency tree
3. traverse the dependency tree
  1. download the source file
  2. extract the source if it is a tarball
  3. execute build process for single pkg
    1. `ccpkg:execute_build_step("configure", opt)`
    2. `ccpkg:execute_build_step("build", opt)`
    3. `ccpkg:execute_build_step("install", opt)`
  4. copy files into `$arch-$platform` folder

