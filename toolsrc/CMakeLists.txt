cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 0.0.1)

include(ExternalProject)

ExternalProject_Add(
    lua
    PREFIX lua
    URL https://www.lua.org/ftp/lua-5.4.3.tar.gz
    URL_HASH SHA256=f8612276169e3bfcbcfb8f226195bfc6e466fe13042f1076cbde92b7ec96bbfb
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE TRUE
    INSTALL_COMMAND make INSTALL_TOP=<INSTALL_DIR> install
)

ExternalProject_Add(
    curl
    PREFIX curl
    URL https://github.com/curl/curl/archive/refs/tags/curl-7_81_0.tar.gz
    URL_HASH SHA256=389aadc5ffb0e801683a62ba6d4eb6fc61c808276a915189cd2470825046ddae
    INSTALL_COMMAND cmake --install . --prefix <INSTALL_DIR>
)

add_executable(ccpkg main.cc)

