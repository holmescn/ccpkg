/*
** $Id: libfs.cc $
** filesystem library
*/

#include <cassert>
#include <cstring>
#include <filesystem>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#define FS_PATH "fs.path"

namespace fs = std::filesystem;

static int fs_path(lua_State *L) {
  int n;
  void *mem;
  fs::path *path = NULL;

  /* fs.path {'p1', 'p2'} */
  if (lua_type(L, 1) == LUA_TTABLE) {
    n = luaL_len(L, 1);
    /* discard extra arguments */
    lua_settop(L, 1);
    for (int i = 1; i <= n; ++i) {
      if (lua_geti(L, 1, i) != LUA_TSTRING) {
        luaL_error(L, "bad element #%d to 'path' argument: string expected, got %s", i, lua_typename(L, lua_type(L, -1)));
      }
    }
    mem = lua_newuserdata(L, sizeof(fs::path));
    assert(mem != NULL);

    for (int i = 2; i <= n + 1; ++i) {
      if (path == NULL) {
        path = new (mem) fs::path(lua_tostring(L, i));
      } else {
        path->append(lua_tostring(L, i));
      }
    }
  } else { /* fs.path ('p1', 'p2') */
    n = lua_gettop(L);
    for (int i = 1; i <= n; ++i) {
      luaL_checktype(L, i, LUA_TSTRING);
    }
    mem = lua_newuserdata(L, sizeof(fs::path));
    assert(mem != NULL);

    for (int i = 1; i <= n; ++i) {
      if (path == NULL) {
        path = new (mem) fs::path(lua_tostring(L, i));
      } else {
        path->append(lua_tostring(L, i));
      }
    }
  }

  luaL_getmetatable(L, FS_PATH);
  lua_setmetatable(L, -2);

  return 1;
}

static fs::path *check_fs_path(lua_State *L, int i = 1) {
  void *ud = luaL_checkudata(L, i, FS_PATH);
  luaL_argcheck(L, ud != NULL, 1, "`fs.path' expected");
  return reinterpret_cast<fs::path*>(ud);
}

static int fs_path_gc(lua_State *L) {
  fs::path *p = check_fs_path(L);
  p->~path();
  return 0;
}

static int fs_path_append(lua_State *L) {
  fs::path *lhs = check_fs_path(L);
  if ( lua_type(L, 2) == LUA_TUSERDATA ) {
    fs::path *rhs = check_fs_path(L, 2);
    lhs->append(rhs->c_str());
  } else {
    luaL_checktype(L, 2, LUA_TSTRING);
    lhs->append(lua_tostring(L, 2));
  }
  lua_pushvalue(L, 1);
  return 1;
}

static int fs_path_tostring(lua_State *L) {
  fs::path *p = check_fs_path(L);
  lua_pushstring(L, p->c_str());
  return 1;
}

static int fs_path_exists(lua_State *L) {
  fs::path *p = check_fs_path(L);
  lua_pushboolean(L, fs::exists(*p));
  return 1;
}

static int fs_relative(lua_State *L) {
  fs::path *p = NULL, *base = NULL;
  bool new_p = false;
  bool new_base = false;
  if ( lua_type(L, 1) == LUA_TUSERDATA ) {
    p = check_fs_path(L);
  } else {
    luaL_checktype(L, 1, LUA_TSTRING);
    p = new fs::path(lua_tostring(L, 1));
    new_p = true;
  }

  if (lua_gettop(L) == 2) {
    if ( lua_type(L, 2) == LUA_TUSERDATA ) {
      base = check_fs_path(L, 2);
    } else {
      luaL_checktype(L, 2, LUA_TSTRING);
      base = new fs::path(lua_tostring(L, 2));
      new_base = true;
    }
  } else {
    luaL_error(L, "too many arguments");
  }

  if (base) {
    try {
      auto r = fs::relative(*p, *base);
      lua_pushstring(L, r.c_str());
    } catch (const std::exception &e) {
      luaL_error(L, "error: %s", e.what());
    }
  } else {
    try {
      auto r = fs::relative(*p);
      lua_pushstring(L, r.c_str());
    } catch (const std::exception &e) {
      luaL_error(L, "error: %s", e.what());
    }
  }

  if (new_base) delete base;
  if (new_p) delete p;

  lua_getglobal(L, "fs");
  lua_getfield(L, -1, "path");
  lua_pushvalue(L, -3);
  lua_call(L, 1, 1);

  return 1;
}

static const luaL_Reg fslib[] = {
  { "path", fs_path },
  { "relative", fs_relative },
  { NULL, NULL }
};

static const luaL_Reg fs_path_meta[] = {
  { "__gc", fs_path_gc },
  { "__div", fs_path_append },
  { "__tostring", fs_path_tostring },
  { "exists", fs_path_exists },
  { NULL, NULL }
};

/*
** Open fs library
*/
LUAMOD_API int luaopen_fs (lua_State *L) {
  luaL_newmetatable(L, FS_PATH);

  lua_pushvalue(L, -1);  /* pushes the metatable */
  lua_setfield(L, -2, "__index"); /* mt.__index = mt */
  for (const luaL_Reg *entry = fs_path_meta; entry->func; ++entry) {
    lua_pushcfunction(L, entry->func);
    lua_setfield(L, -2, entry->name);
  }

  luaL_newlib(L, fslib);
  return 1;
}
