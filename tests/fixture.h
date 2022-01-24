#include <fstream>
#include <filesystem>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

namespace fs = std::filesystem;

LUAMOD_API int luaopen_fs (lua_State *L);
LUAMOD_API int luaext_os (lua_State *L);

struct TestFixture {
  const char *filename = "/tmp/test.lua";
  lua_State *L;
  TestFixture () {
    L = luaL_newstate();
    luaL_openlibs(L);
    luaL_requiref(L, "fs", luaopen_fs, 1);
    lua_pop(L, 1);
    luaext_os(L);
  }
  ~TestFixture () {
    lua_close(L);
    fs::remove(filename);
  }
  inline int run(const std::string code) {
    std::ofstream o(filename, std::ios::trunc);
    o << code;
    o.close();
    return luaL_dofile(L, filename);
  }
  inline std::string error() {
    int top = lua_gettop(L);
    std::string e = lua_tostring(L, top);
    lua_pop(L, top);
    return e;
  }

  inline std::string G_type(const char *name) {
    std::string t;
    lua_getglobal(L, name);
    t = lua_typename(L, lua_type(L, -1));
    lua_pop(L, 1);
    return t;
  }

  std::string G_value(const char *name) {
    std::string v;
    lua_getglobal(L, "tostring");
    lua_getglobal(L, name);
    lua_call(L, 1, 1);
    v = lua_tostring(L, -1);
    lua_pop(L, 1);
    return v;
  }
};
