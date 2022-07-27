cmake_minimum_required(VERSION 3.18)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)

# Add external projects
include(ExternalProject)
ExternalProject_Add(lua54
  URL               https://www.lua.org/ftp/lua-5.4.4.tar.gz
  URL_HASH          SHA256=164c7849653b80ae67bec4b7473b884bf5cc8d2dca05653475ec2ed27b9ebf61
  PREFIX            external/lua54
  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ${CMAKE_MAKE_PROGRAM} -C ../lua54
  INSTALL_COMMAND   ${CMAKE_MAKE_PROGRAM} -C ../lua54 INSTALL_TOP=${CMAKE_CURRENT_BINARY_DIR}/external/lua54 install
)


ExternalProject_Get_Property(lua54 INSTALL_DIR)
message(STATUS "Lua 5.4 install dir: ${INSTALL_DIR}")
include_directories(${INSTALL_DIR}/include)
set(LUA_LIBRARY_DIR ${INSTALL_DIR}/lib)

ExternalProject_Add(mbedTLS
  GIT_REPOSITORY  https://github.com/Mbed-TLS/mbedtls.git
  GIT_TAG         v3.2.1
  PREFIX          external/mbedTLS
  INSTALL_COMMAND cmake --install .  --prefix=${CMAKE_CURRENT_BINARY_DIR}/external/mbedTLS
)

ExternalProject_Get_Property(mbedTLS INSTALL_DIR)
message(STATUS "mbedTLS 3.2.1 install dir: ${INSTALL_DIR}")
include_directories(${INSTALL_DIR}/include)
set(mbedTLS_LIBRARY_DIR ${INSTALL_DIR}/lib)

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
add_compile_definitions(LUA_COMPAT_5_2=1)

option(UT "unit test mode" OFF)

if (UT)
  ExternalProject_Add(Catch2
    GIT_REPOSITORY  https://github.com/catchorg/Catch2.git
    GIT_TAG         v3.1.0
    PREFIX          external/Catch2
	INSTALL_COMMAND cmake --install . --prefix=${CMAKE_CURRENT_BINARY_DIR}/external/Catch2
  )
  ExternalProject_Get_Property(Catch2 INSTALL_DIR)
  list(APPEND CMAKE_MODULE_PATH "${INSTALL_DIR}/lib/cmake")
  message(STATUS "Catch2 install dir: ${INSTALL_DIR}")

  #add_executable(tests tests/fixture.cc tests/test_ext_os.cc src/libext_os.cc src/process.cc)
  #target_link_libraries(
  #  tests
  #  PRIVATE
  #  ${LUA_LIBRARIES}
  #  Catch2::Catch2WithMain)

  #include(CTest)
  #include(Catch)
  #catch_discover_tests(tests)
else()
  add_executable(ccpkg src/main.c src/libext_os.cc src/process.cc)
  target_link_libraries(ccpkg PRIVATE ${LUA_LIBRARIES})
endif()
