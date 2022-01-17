/*
** $Id: lfs.c $
** filesystem library
*/

#include <filesystem>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

namespace fs = std::filesystem;

static int fs_currentdir(lua_State *L) {
  auto curdir = fs::current_path();
  lua_pushstring(L, curdir.c_str());
  return 1;
}

static int fs_mkdirs(lua_State *L) {
  const char *dirs = luaL_checkstring(L, 1);
  try {
    fs::create_directories(dirs);
  } catch (const std::exception &e) {
    lua_pushstring(L, e.what());
    lua_error(L);
  }
  return 0;
}

static int fs_exists(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  lua_pushboolean(L, fs::exists(path));
  return 1;
}

static const luaL_Reg ccpkglib[] = {
  { "currentdir", fs_currentdir },
  { "mkdirs", fs_mkdirs },
  { "exists", fs_exists },
  { NULL, NULL }
};

/*
** Open ccpkg library
*/
LUAMOD_API int luaopen_fs (lua_State *L) {
  luaL_newlib(L, ccpkglib);
  return 1;
}
