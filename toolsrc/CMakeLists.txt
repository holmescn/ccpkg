cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

find_package(Lua REQUIRED)

include_directories(${LUA_INCLUDE_DIR})

option(DEV_MODE "development mode" OFF)

add_library(fs STATIC libfs.cc)
target_link_libraries(
  fs

  PRIVATE
  ${LUA_LIBRARIES}
)

add_library(path STATIC libpath.cc)
target_link_libraries(
  path

  PRIVATE
  ${LUA_LIBRARIES}
)

add_library(ext_os STATIC libext_os.cc)
target_link_libraries(
  ext_os

  PRIVATE
  ${LUA_LIBRARIES}
)

if (DEV_MODE)
  find_package(Catch2 CONFIG REQUIRED)

  add_executable(test_os_run tests/test_os_run.cc)
  target_link_libraries(test_os_run PRIVATE ext_os ${LUA_LIBRARIES} Catch2::Catch2WithMain)

  add_executable(test_path_join tests/test_path_join.cc)
  target_link_libraries(test_path_join PRIVATE path ${LUA_LIBRARIES} Catch2::Catch2WithMain)

  include(CTest)
  include(Catch)
  catch_discover_tests(test_os_run)
  catch_discover_tests(test_path_join)
else()
  add_executable(ccpkg main.c ccpkg.c)
  target_link_libraries(
    ccpkg

    PRIVATE
    fs path ext_os
    ${LUA_LIBRARIES}
  )

  #if (LINUX OR UNIX)
  #    target_compile_definitions(
  #        ccpkg
  #        PRIVATE LINUX
  #    )
  #endif()
endif()
