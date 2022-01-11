cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 0.0.1)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

include(ExternalProject)

ExternalProject_Add(
    lua
    PREFIX deps
    URL https://www.lua.org/ftp/lua-5.4.3.tar.gz
    URL_HASH SHA256=f8612276169e3bfcbcfb8f226195bfc6e466fe13042f1076cbde92b7ec96bbfb
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE TRUE
    INSTALL_COMMAND make INSTALL_TOP=<INSTALL_DIR> install
)

ExternalProject_Add(
    curl
    PREFIX deps
    URL https://github.com/curl/curl/archive/refs/tags/curl-7_81_0.tar.gz
    URL_HASH SHA256=389aadc5ffb0e801683a62ba6d4eb6fc61c808276a915189cd2470825046ddae
    INSTALL_COMMAND cmake --install . --prefix <INSTALL_DIR>
)

link_directories(${CMAKE_CURRENT_BINARY_DIR}/deps/lib)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/deps/include)

add_executable(ccpkg main.c)
add_dependencies(ccpkg lua curl)

target_link_libraries(
    ccpkg

    PRIVATE
    liblua.a
    m
    dl
)
