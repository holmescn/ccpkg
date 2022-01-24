cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

find_package(Lua REQUIRED)

include_directories(${LUA_INCLUDE_DIR})

option(DEV "development mode" OFF)

add_library(ext_os STATIC src/libext_os.cc)
target_link_libraries(
  ext_os

  PRIVATE
  ${LUA_LIBRARIES}
)

if (DEV)
  include(FetchContent)
  FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        v3.0.0-preview4
  )
  FetchContent_MakeAvailable(Catch2)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}/_deps/catch2-src/extras")

  add_executable(tests tests/test_ext_os.cc)
  target_link_libraries(tests PRIVATE ext_os ${LUA_LIBRARIES} Catch2::Catch2WithMain)

  include(CTest)
  include(Catch)
  catch_discover_tests(tests)
else()
  add_executable(ccpkg src/main.c)
  target_link_libraries(
    ccpkg

    PRIVATE
    ext_os
    ${LUA_LIBRARIES}
  )

  #if (LINUX OR UNIX)
  #    target_compile_definitions(
  #        ccpkg
  #        PRIVATE LINUX
  #    )
  #endif()
endif()
