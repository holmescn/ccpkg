#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <filesystem>

namespace fs = std::filesystem;

static int ext_os_path_join (lua_State *L) {
  int n, i_begin = 0, i_end = 0;
  fs::path p;

  if ( lua_type(L, 1) == LUA_TTABLE ) {
    luaL_checktype(L, 1, LUA_TTABLE);
    n = luaL_len(L, 1);
    for (int i = 1; i <= n; ++i) {
      if (lua_geti(L, 1, i) != LUA_TSTRING) {
        luaL_error(L, "bad element #%d: string expected, got %s", i, lua_typename(L, lua_type(L, -1)));
      }
    }
    i_begin = 2;
    i_end = n + 1;
  } else {
    n = lua_gettop(L);
    for (int i = 1; i <= n; ++i) {
      luaL_checktype(L, i, LUA_TSTRING);
    }
    i_begin = 1;
    i_end = n;
  }
  for (int i = i_begin; i_begin > 0 && i <= i_end; ++i) {
    if (p.empty()) {
      p = fs::path(lua_tostring(L, i));
    } else {
      p.append(lua_tostring(L, i));
    }
  }
  if (p.empty()) {
    lua_pushstring(L, "");
  } else {
    lua_pushstring(L, p.c_str());
  }
  return 1;
}

static int ext_os_path_exists (lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  lua_pushboolean(L, (s ? fs::exists(s) : false));
  return 1;
}

static int ext_os_path_relative (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  const char *base = luaL_checkstring(L, 2);
  try {
    fs::path r = fs::relative(path, base);
    lua_pushstring(L, r.c_str());
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 1;
}

static const luaL_Reg ext_os_path[] = {
  { "join", ext_os_path_join },
  { "exists", ext_os_path_exists },
  { "relative", ext_os_path_relative },
  { NULL, NULL }
};

LUALIB_API void luaopen_ext_os_path(lua_State *L) {
  lua_createtable(L, 0, sizeof(ext_os_path)/sizeof(ext_os_path[0]));
  luaL_setfuncs(L, ext_os_path, 0);
  lua_setfield(L, -2, "path");
}