# DESIGN

## `ccpkg install` command

1. load `project.lua` file and do init
2. for each element in `project.dependencies`
  1. check pkg port exists
  2. check pkg version exists
  3. generate a build list
  4. sort the build list
  5. check conflict
3. for each element in build list
  1. download the source file
  2. extract the source if it is a tarball
  3. execute build process for single pkg
    1. `ccpkg:execute_build_step("configure", opt)`
    2. `ccpkg:execute_build_step("build", opt)`
    3. `ccpkg:execute_build_step("install", opt)`
  4. copy files into `$arch-$platform` folder

