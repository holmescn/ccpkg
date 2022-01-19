#include <string>
#include <catch.hpp>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

LUALIB_API int f_os_run (lua_State *L);

struct TestFixture {
  lua_State *L;

  TestFixture() {
    L = luaL_newstate();
    luaL_openlibs(L);

    lua_getglobal(L, "os");
    lua_pushcfunction(L, f_os_run);
    lua_setfield(L, -2, "run");
  }
  ~TestFixture() {
    lua_pop(L, lua_gettop(L));
    lua_close(L);
  }

  int run(const std::string script) {
    return luaL_dostring(L, script.c_str());
  }
  std::string err(void) {
    std::string r = lua_tostring(L, lua_gettop(L));
    lua_pop(L, lua_gettop(L));
    return r;
  }
};

TEST_CASE_METHOD( TestFixture, "cmd field must exists", "[cmd]") {
  REQUIRE ( run("os.run {} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {} \"]:1: bad field `cmd`: string expected, got nil" );
}

TEST_CASE_METHOD( TestFixture, "cmd field must be string", "[cmd]") {
  REQUIRE ( run("os.run {cmd=1} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd=1} \"]:1: bad field `cmd`: string expected, got number" );
  REQUIRE ( run("os.run {cmd=true} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd=true} \"]:1: bad field `cmd`: string expected, got boolean" );
  REQUIRE ( run("os.run {cmd={}} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd={}} \"]:1: bad field `cmd`: string expected, got table" );
}

TEST_CASE_METHOD( TestFixture, "out field must be string", "[cmd]") {
  REQUIRE ( run("os.run {cmd='', out=1} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='', out=1} \"]:1: bad field `out`: string expected, got number" );
  REQUIRE ( run("os.run {cmd='', out=true} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='', out=true} \"]:1: bad field `out`: string expected, got boolean" );
  REQUIRE ( run("os.run {cmd='', out={}} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='', out={}} \"]:1: bad field `out`: string expected, got table" );
}

TEST_CASE_METHOD( TestFixture, "args field is required", "[args]") {
  REQUIRE ( run("os.run {cmd='/bin/ls'} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='/bin/ls'} \"]:1: bad field `args`: table expected, got nil" );
}

TEST_CASE_METHOD( TestFixture, "each element of `args` must be string", "[args]") {
  REQUIRE ( run("os.run {cmd='/bin/ls', args={1, 2, 3}} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='/bin/ls', args={1, 2, 3}} \"]:1: bad element #1 of `args`: string expected, got number" );
}

TEST_CASE_METHOD( TestFixture, "envs element should be string", "[envs]") {
  REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}, envs={1,2,3}} ") != LUA_OK );
  REQUIRE ( err() == "[string \"os.run {cmd='/bin/ls', args={'-l', '-a'}, env...\"]:1: bad element #1 of `envs`: string expected, got number" );
}

TEST_CASE_METHOD( TestFixture, "normal", "[run]") {
  REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}}") == LUA_OK );
  REQUIRE ( run("os.run {cmd='/bin/ls', args={'-l', '-a'}, envs={'V=1', 'V=2'}, out='ls.log'}") == LUA_OK );
}
