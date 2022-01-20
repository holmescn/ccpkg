cmake_minimum_required(VERSION 3.0)
project(BZip2)

set(SRCS
  blocksort.c
  huffman.c
  crctable.c
  randtable.c
  compress.c
  decompress.c
  bzlib.c
)

add_library(bz2-shared SHARED ${SRCS})
set_target_properties(bz2-shared
  PROPERTIES OUTPUT_NAME "bz2"
  POSITION_INDEPENDENT_CODE 1)

add_library(bz2-static STATIC ${SRCS})
set_target_properties(bz2-static
  PROPERTIES OUTPUT_NAME "bz2")

install(TARGETS bz2-shared bz2-static)