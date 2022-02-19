#include "catch2/catch_test_macros.hpp"
#include "fixture.h"
#include <cstdio>
#include <chrono>
#include <thread>
#include <filesystem>

using namespace std::chrono_literals;
namespace fs = std::filesystem;

TEST_CASE_METHOD( TestFixture, "os.which", "[ext.os]") {
  REQUIRE ( run("x = os.which('bash') ") == LUA_OK );
  REQUIRE ( value("x") == "/usr/bin/bash" );
  REQUIRE ( run("x = os.which('env') ") == LUA_OK );
  REQUIRE ( value("x") == "/usr/bin/env" );
  REQUIRE ( run("x = os.which('unknown') ") == LUA_OK );
  REQUIRE ( type("x") == "nil" );
}

TEST_CASE_METHOD( TestFixture, "os.path.relpath", "[ext.os]") {
  SECTION("no second argument") {
    REQUIRE ( run("x = os.path.relpath('/tmp/test') ") == LUA_OK );
    REQUIRE ( value("x") == "../test" );
  }
  REQUIRE ( run("x = os.path.relpath('/tmp/test', '/var') ") == LUA_OK );
  REQUIRE ( value("x") == "../tmp/test" );
}

TEST_CASE_METHOD( TestFixture, "os.path.abspath", "[ext.os]") {
  REQUIRE ( run("x = os.path.abspath('/tmp/../var') ") == LUA_OK );
  REQUIRE ( value("x") == "/var" );
  REQUIRE ( run("x = os.path.abspath('/tmp/a/../not-exists') ") == LUA_OK );
  REQUIRE ( value("x") == "/tmp/not-exists" );
}

TEST_CASE_METHOD( TestFixture, "os.path.basename", "[ext.os]") {
  REQUIRE ( run("x = os.path.basename('/tmp/filename.tar.gz') ") == LUA_OK );
  REQUIRE ( value("x") == "filename.tar.gz" );
}

TEST_CASE_METHOD( TestFixture, "os.run", "[ext.os]") {
  SECTION("bad argument") {
    SECTION("bad argument #1") {
      REQUIRE( run("os.run(1, 1)") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad argument #1 to 'run' (table or string expected, got number)" );
    }
    SECTION("bad argument #1 with zero length") {
      REQUIRE( run("os.run('', 1)") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad argument #1 to 'run' (length should > 0)" );

      REQUIRE( run("os.run({}, 1)") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad argument #1 to 'run' (length should > 0)" );
    }
    SECTION("bad argument #1 element") {
      REQUIRE( run("os.run({1,2,3}, 1)") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad element #1 in argument #1 to 'run' (string expected, got number)" );
    }
    SECTION("bad argument #2") {
      REQUIRE( run("os.run('ls', 1)") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad argument #2 to 'run' (table expected, got number)" );
    }
    SECTION("bad argument #2 element 'file'") {
      REQUIRE( run("os.run('ls', {file=1})") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad element 'file' in argument #2 to 'run' (string expected, got number)" );
    }
    SECTION("bad argument #2 element 'cwd'") {
      REQUIRE( run("os.run('ls', {cwd=1})") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad element 'cwd' in argument #2 to 'run' (string expected, got number)" );
    }
    SECTION("bad argument #2 element 'env'") {
      REQUIRE( run("os.run('ls', {env=1})") != LUA_OK );
      REQUIRE( error() == "/tmp/test.lua:1: bad element 'env' in argument #2 to 'run' (string expected, got number)" );
    }
  }

  SECTION("write output to /dev/null") {
    REQUIRE( run("r = os.run('/usr/bin/ls', {})") == LUA_OK );
    REQUIRE( value("r", "exit_code") == "0" );
  }

  SECTION("write output to file") {
    const char *filename = "/tmp/test.1.log";
    if (fs::exists(filename)) {
      fs::remove(filename);
    }
    REQUIRE( run("os.run('/usr/bin/ls', {file='/tmp/test.1.log'})") == LUA_OK );
    std::this_thread::sleep_for(1ms);
    REQUIRE( fs::exists(filename) );
  }

  SECTION("cmd without full path") {
    const char *filename = "/tmp/test.2.log";
    if (fs::exists(filename)) {
      fs::remove(filename);
    }
    REQUIRE( run("os.run('ls /tmp', {file='/tmp/test.2.log'})") == LUA_OK );
    std::this_thread::sleep_for(1ms);
    REQUIRE( fs::exists(filename) );
  }

  SECTION("check exit failed") {
    REQUIRE( run("r = os.run('ls -5', {check=true})") != LUA_OK );
    REQUIRE( error() == "/tmp/test.lua:1: 'run' exit with code 2" );
  }

  SECTION("capture output") {
    REQUIRE( run("r = os.run('ls /tmp', {capture_output=true})") == LUA_OK );
    REQUIRE( value("r", "stdout") != "" );
  }

  SECTION("capture output and check") {
    REQUIRE( run("r = os.run('ls -5', {capture_output=true, check=true})") != LUA_OK );
    REQUIRE( error() == "/tmp/test.lua:1: 'run' exit with code 2" );
  }
}
