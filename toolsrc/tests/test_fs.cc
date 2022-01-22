#include "catch2/catch_test_macros.hpp"
#include "fixture.h"

struct FsTestFixture : public TestFixture {

};

TEST_CASE_METHOD( FsTestFixture, "fs.path(...)", "[fs.path]" ) {
  SECTION("table argument with bad elements") {
    REQUIRE ( run("fs.path {1,2}") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad element #1 to 'path' argument: string expected, got number" );
    REQUIRE ( run("fs.path {'1', 2}") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad element #2 to 'path' argument: string expected, got number" );
  }
  SECTION("multiple arguments with bad argument") {
    REQUIRE ( run("fs.path(1, 2)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #1 to 'path' (string expected, got number)" );
    REQUIRE ( run("fs.path('1', 2)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #2 to 'path' (string expected, got number)" );
  }
  SECTION("success") {
    REQUIRE ( run("x = fs.path('/tmp', 'a')") == LUA_OK );
    REQUIRE ( G_type("x") == "userdata" );
    REQUIRE ( G_value("x") == "/tmp/a" );
    REQUIRE ( run("x = fs.path{'/tmp', 'a'}") == LUA_OK );
    REQUIRE ( G_value("x") == "/tmp/a" );
  }
}

TEST_CASE_METHOD( FsTestFixture, "fs.path:exists", "[fs.path]" ) {
  REQUIRE ( run("x = fs.path('/tmp'):exists()") == LUA_OK );
  REQUIRE ( G_type("x") == "boolean" );
  REQUIRE ( G_value("x") == "true" );
}

TEST_CASE_METHOD( FsTestFixture, "tostring(fs.path(...))", "[fs.path]" ) {
  REQUIRE ( run("x = tostring(fs.path('/tmp'))") == LUA_OK );
  REQUIRE ( G_value("x") == "/tmp" );
}

TEST_CASE_METHOD( FsTestFixture, "fs.path concat", "[fs.path]" ) {
  SECTION("bad argument") {
    REQUIRE ( run("x = fs.path('/tmp') / 1") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #2 to '__div' (string expected, got number)" );
  }

  SECTION("good argument") {
    REQUIRE ( run("x = fs.path('/tmp') / 'a'") == LUA_OK );
    REQUIRE ( G_value("x") == "/tmp/a" );
    REQUIRE ( run("x = fs.path('/tmp') / fs.path('b')") == LUA_OK );
    REQUIRE ( G_value("x") == "/tmp/b" );
  }
}

TEST_CASE_METHOD( FsTestFixture, "fs.relative", "[fs]" ) {
  SECTION("bad argument #1") {
    REQUIRE ( run("x = fs.relative(1, 2)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #1 to 'relative' (string expected, got number)" );
    REQUIRE ( run("x = fs.relative(true, 2)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #1 to 'relative' (string expected, got boolean)" );
  }
  SECTION("bad argument #2") {
    REQUIRE ( run("x = fs.relative('/tmp', 2)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #2 to 'relative' (string expected, got number)" );
    REQUIRE ( run("x = fs.relative(fs.path('/tmp'), true)") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #2 to 'relative' (string expected, got boolean)" );
  }
  SECTION("too many arguments") {
    REQUIRE ( run("x = fs.relative('/tmp/a/b', '/tmp/a/c', '1')") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: too many arguments" );
  }
  SECTION("examples") {
    REQUIRE ( run("x = fs.relative('/tmp/a/b', '/tmp/a/c')") == LUA_OK );
    REQUIRE ( G_type("x") == "userdata" );
    REQUIRE ( G_value("x") == "../b" );
    REQUIRE ( run("x = fs.relative(fs.path('/tmp/a/b'), '/tmp/a/c')") == LUA_OK );
    REQUIRE ( G_value("x") == "../b" );
    REQUIRE ( run("x = fs.relative('/tmp/a/b', fs.path('/tmp/a/c'))") == LUA_OK );
    REQUIRE ( G_value("x") == "../b" );
    REQUIRE ( run("x = fs.relative(fs.path('/tmp/a/b'), fs.path('/tmp/a/c'))") == LUA_OK );
    REQUIRE ( G_value("x") == "../b" );
  }
}