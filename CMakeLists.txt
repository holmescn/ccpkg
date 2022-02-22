cmake_minimum_required(VERSION 3.18)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)

# CYGWIN, MSYS, MINGW, FreeBSD
if (UNIX AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
  add_compile_definitions(LUA_USE_LINUX=1)
elseif(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  add_compile_definitions(LUA_USE_MACOSX=1)
elseif(WIN32 AND CMAKE_SYSTEM_NAME STREQUAL "Windows")
  add_compile_definitions(LUA_USE_WINDOWS=1)
else()
  message(FATAL_ERROR "unsupported system")
endif()

find_package(Lua REQUIRED)

include_directories(${LUA_INCLUDE_DIR})

option(DEV "development mode" OFF)

if (DEV)
  include(FetchContent)
  FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        v3.0.0-preview4
  )
  FetchContent_MakeAvailable(Catch2)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}/_deps/catch2-src/extras")

  add_executable(tests tests/fixture.cc tests/test_ext_os.cc src/libext_os.cc src/process.cc)
  target_link_libraries(
    tests
    PRIVATE
    ${LUA_LIBRARIES}
    Catch2::Catch2WithMain)

  include(CTest)
  include(Catch)
  catch_discover_tests(tests)
else()
  add_executable(ccpkg src/main.c src/libext_os.cc src/process.cc)
  target_link_libraries(ccpkg PRIVATE ${LUA_LIBRARIES})
endif()
