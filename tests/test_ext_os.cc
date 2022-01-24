#include "catch2/catch_test_macros.hpp"
#include "fixture.h"

struct ExtOsTestFixture : public TestFixture {

};

TEST_CASE_METHOD( ExtOsTestFixture, "argument check", "[ext.os]") {
  SECTION("cmd field must exists") {
    REQUIRE ( run("os.run {} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `cmd`: string expected, got nil" );
  }

  SECTION("cmd field must be string") {
    REQUIRE ( run("os.run {cmd=1} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `cmd`: string expected, got number" );
    REQUIRE ( run("os.run {cmd=true} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `cmd`: string expected, got boolean" );
    REQUIRE ( run("os.run {cmd={}} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `cmd`: string expected, got table" );
  }
  SECTION("out field must be string") {
    REQUIRE ( run("os.run {cmd='', out=1} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `out`: string expected, got number" );
    REQUIRE ( run("os.run {cmd='', out=true} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `out`: string expected, got boolean" );
    REQUIRE ( run("os.run {cmd='', out={}} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `out`: string expected, got table" );
  }
  SECTION("args field is required") {
    REQUIRE ( run("os.run {cmd='/bin/ls'} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad field `args`: table expected, got nil" );
  }
  SECTION("each element of `args` must be string") {
    REQUIRE ( run("os.run {cmd='/bin/ls', args={1, 2, 3}} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad element #1 of `args`: string expected, got number" );
  }
  SECTION( "envs element should be string" ) {
    REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}, envs={1,2,3}} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad element #1 of `envs`: string expected, got number" );
  }
}

TEST_CASE_METHOD( ExtOsTestFixture, "example", "[os.run]") {
  REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}}") == LUA_OK );
  REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}, envs={'V=1', 'V=2'}, out='ls.log'}") == LUA_OK );
  REQUIRE ( fs::exists("ls.log") );
}
