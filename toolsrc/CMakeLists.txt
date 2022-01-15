cmake_minimum_required(VERSION 3.21)

project(ccpkg VERSION 1.0.0 DESCRIPTION "A vcpkg-like" LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

find_package(Lua REQUIRED)

include_directories(${LUA_INCLUDE_DIR})

add_executable(ccpkg main.c lccpkg.c)

target_link_libraries(
  ccpkg

  PRIVATE
  ${LUA_LIBRARIES}
)

#if (LINUX OR UNIX)
#    target_compile_definitions(
#        ccpkg
#        PRIVATE LINUX
#    )
#endif()
