#include <string>
#include <catch.hpp>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

LUAMOD_API int luaopen_path (lua_State *L);

struct TestFixture {
  lua_State *L;

  TestFixture() {
    L = luaL_newstate();
    luaL_openlibs(L);
    luaL_requiref(L, "path", luaopen_path, 1);
    lua_pop(L, 1);
  }
  ~TestFixture() {
    lua_pop(L, lua_gettop(L));
    lua_close(L);
  }

  int run(const std::string script) {
    return luaL_dostring(L, script.c_str());
  }
  std::string err(void) {
    std::string s = lua_tostring(L, lua_gettop(L));
    lua_pop(L, lua_gettop(L));
    return s;
  }
  std::string G(const char *name) {
    std::string s;
    lua_getglobal(L, name);
    s = lua_tostring(L, -1);
    lua_pop(L, 1);
    return s;
  }
};

TEST_CASE_METHOD( TestFixture, "empty table isn't allowed", "[path]") {
  REQUIRE ( run("path.join {} ") != LUA_OK );
  REQUIRE ( err() == "[string \"path.join {} \"]:1: empty table isn't allowed" );
}

TEST_CASE_METHOD( TestFixture, "non-string elements isn't allowed", "[path]") {
  REQUIRE ( run("path.join {'/', 1, 2} ") != LUA_OK );
  REQUIRE ( err() == "[string \"path.join {'/', 1, 2} \"]:1: bad element #2: string expected, got number" );
}

TEST_CASE_METHOD( TestFixture, "first is root path", "[path]") {
  REQUIRE ( run("x = path.join {'/root', 'a', 'b'} ") == LUA_OK );
  REQUIRE ( G("x") == "/root/a/b" );
}

TEST_CASE_METHOD( TestFixture, "first is not root path", "[path]") {
  REQUIRE ( run("x = path.join {'root', 'a', 'b'} ") == LUA_OK );
  REQUIRE ( G("x") == "root/a/b" );
}

TEST_CASE_METHOD( TestFixture, "call with other type", "[path]") {
  REQUIRE ( run("x = path.join (1, 'a') ") != LUA_OK );
  REQUIRE ( err() == "[string \"x = path.join (1, 'a') \"]:1: bad argument #1 to 'join' (table expected, got number)");
}

TEST_CASE_METHOD( TestFixture, "call inside another function", "[path]") {
  REQUIRE ( run("x, w = (function (x, t) return path.join(t), x + 1 end)(1, {'/'})") == LUA_OK );
  REQUIRE ( G("x") == "/" );
}
