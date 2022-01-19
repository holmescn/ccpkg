cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

find_package(Lua REQUIRED)

include_directories(${LUA_INCLUDE_DIR})

option(DEV_MODE "development mode" OFF)

add_library(fs STATIC lfs.cc)
target_link_libraries(
  fs

  PRIVATE
  ${LUA_LIBRARIES}
)

if (DEV_MODE)
  find_package(Catch2 CONFIG REQUIRED)

  add_executable(test_os_run tests/test_os_run.cc os_run.c)
  target_link_libraries(
    test_os_run

    PRIVATE
    ${LUA_LIBRARIES}
    Catch2::Catch2WithMain)
  include(CTest)
  include(Catch)
  catch_discover_tests(test_os_run)
else()
  add_executable(ccpkg main.c os_run.c)
  target_link_libraries(
    ccpkg

    PRIVATE
    fs
    ${LUA_LIBRARIES}
  )

  #if (LINUX OR UNIX)
  #    target_compile_definitions(
  #        ccpkg
  #        PRIVATE LINUX
  #    )
  #endif()
endif()