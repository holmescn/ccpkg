/*
** $Id: libpath.cc $
** path library
*/

#include <cassert>
#include <filesystem>

#include <lua.h>
#include "lualib.h"
#include "lauxlib.h"

namespace fs = std::filesystem;

/**
 * @brief join a series of path
 * 
 * local path = path.join{'/root/path', 'part1', 'part2'}
 */
static int path_join(lua_State *L) {
  fs::path path;
  if (lua_gettop(L) == 1) {
    luaL_checktype(L, 1, LUA_TTABLE);

    int n = luaL_len(L, 1);
    if (n == 0) {
      return luaL_error(L, "empty table isn't allowed");
    }

    for (int i = 1; i <= n; ++i) {
      const char *s;
      lua_pushinteger(L, i);
      lua_gettable(L, 1);
      if ( lua_type(L, -1) != LUA_TSTRING ) {
        return luaL_error(L, "bad element #%d: string expected, got %s", i, lua_typename(L, lua_type(L, -1)));
      }
      s = lua_tostring(L, -1);
      if (i == 1) {
        path = fs::path(s);
      } else {
        path /= s;
      }
      lua_pop(L, 1);
    }
  } else {
    for (int i = 1; i <= lua_gettop(L); ++i) {
      const char *s = luaL_checkstring(L, i);
      if (i == 1) {
        path = fs::path(s);
      } else {
        path /= s;
      }
    }
  }

  lua_pushstring(L, path.c_str());
  return 1;
}

static int path_filename(lua_State *L) {
  fs::path path(luaL_checkstring(L, 1));
  lua_pushstring(L, path.filename().c_str());
  return 1;
}

static int path_has_root_path(lua_State *L) {
  fs::path path(luaL_checkstring(L, 1));
  lua_pushboolean(L, path.has_root_path());
  return 1;
}

static const luaL_Reg pathlib[] = {
  { "join", path_join },
  { "filename", path_filename },
  { "has_root_path", path_has_root_path },
  { NULL, NULL }
};

/*
** Open path library
*/
LUAMOD_API int luaopen_path (lua_State *L) {
  luaL_newlib(L, pathlib);
  return 1;
}
