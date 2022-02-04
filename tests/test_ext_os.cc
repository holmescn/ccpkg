#include "catch2/catch_test_macros.hpp"
#include "fixture.h"

struct ExtOsTestFixture : public TestFixture {

};

TEST_CASE_METHOD( ExtOsTestFixture, "os.search_path", "[ext.os]") {
  REQUIRE ( run("x = os.search_path('bash') ") == LUA_OK );
  REQUIRE ( G_value("x") == "/usr/bin/bash" );
}

TEST_CASE_METHOD( ExtOsTestFixture, "os.run", "[ext.os]") {
  SECTION("only accept table-style argument") {
    REQUIRE ( run("os.run('bash', 1, 2) ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #1 to 'run' (table expected, got string)" );
  }
  SECTION("one of cmd or exe is needed") {
    REQUIRE ( run("os.run {} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: one of `cmd` or `exe` is needed" );
  }
  SECTION("exe style need args") {
    REQUIRE ( run("os.run {exe='/usr/bin/bash'} ") != LUA_OK );
    REQUIRE ( error() == "/tmp/test.lua:1: bad argument #args: table expected, got nil" );
  }
  SECTION("cmd-style") {
    SECTION("command not found") {
      REQUIRE ( run("ok, _ = os.run {cmd='invalid-command'} ") != LUA_OK );
      REQUIRE ( error() == "/tmp/test.lua:1: error: execve failed: No such file or directory" );
    }
    SECTION("specify start_dir") {
      REQUIRE ( run("ok, r = os.run {cmd='ls', start_dir='/tmp', out='test.log'}\nexit_code=r.exit_code ") == LUA_OK );
      REQUIRE ( G_value("ok") == "true" );
      REQUIRE ( G_value("exit_code") == "0" );
    }
    SECTION("capture") {
      REQUIRE ( run("ok, r = os.run {cmd='ls', out='capture'}\ntext=r.stderr ") == LUA_OK );
      REQUIRE ( G_value("text") == "" );
    }
  }
}
