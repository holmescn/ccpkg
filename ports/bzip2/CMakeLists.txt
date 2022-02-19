cmake_minimum_required(VERSION 3.20)
project(BZip2)

option(BUILD_SHARED "" ON)
option(BUILD_STATIC "" OFF)

set(SRCS
  blocksort.c
  huffman.c
  crctable.c
  randtable.c
  compress.c
  decompress.c
  bzlib.c
)

if (BUILD_SHARED)
    add_library(bz2-shared SHARED ${SRCS})
    set_target_properties(bz2-shared
        PROPERTIES OUTPUT_NAME "bz2"
        PUBLIC_HEADER "bzlib.h"
        POSITION_INDEPENDENT_CODE 1)
    install(TARGETS bz2-shared)
endif (BUILD_SHARED)

if (BUILD_STATIC)
    add_library(bz2-static STATIC ${SRCS})
    set_target_properties(bz2-static
        PROPERTIES OUTPUT_NAME "bz2"
        PUBLIC_HEADER "bzlib.h")
    install(TARGETS bz2-static)
endif (BUILD_STATIC)
