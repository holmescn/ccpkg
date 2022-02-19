#include "fixture.h"

LUAMOD_API void luaext_os (lua_State *L);

TestFixture::TestFixture() {
  L = luaL_newstate();
  luaL_openlibs(L);
  luaext_os(L);
}

TestFixture::~TestFixture() {
  lua_close(L);
  fs::remove(filename);
}

int TestFixture::run(const std::string &code)  {
  std::ofstream o(filename, std::ios::trunc);
  o << code;
  o.close();
  return luaL_dofile(L, filename);
}

std::string TestFixture::error() {
  int t = lua_gettop(L);
  std::string e = lua_tostring(L, t);
  lua_pop(L, t);
  return e;
}

std::string TestFixture::type(const char *name) {
  std::string t;
  lua_getglobal(L, name);
  t = lua_typename(L, lua_type(L, -1));
  lua_pop(L, 1);
  return t;
}

std::string TestFixture::value(const char *name)  {
  std::string v;
  lua_getglobal(L, "tostring");
  lua_getglobal(L, name);
  lua_call(L, 1, 1);
  v = lua_tostring(L, -1);
  lua_pop(L, 1);
  return v;
}

std::string TestFixture::value(const char *name, const char *field)  {
  std::string v;
  lua_getglobal(L, name);
  lua_getglobal(L, "tostring");
  lua_getfield(L, -2, field);
  lua_call(L, 1, 1);
  v = lua_tostring(L, -1);
  lua_pop(L, 1);
  return v;
}
