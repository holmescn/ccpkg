/*
** $Id: lccpkg.c $
** ccpkg library
*/

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include <errno.h>
#include <string.h>
#include <unistd.h>

static int ccpkg_getcwd(lua_State *L) {
  char path[1024];
  if (getcwd(path, sizeof(path)) == NULL) {
    lua_pushstring(L, "<unknown>");
  } else {
    lua_pushstring(L, path);
  }
  return 1;
}

static int ccpkg_chdir(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  if (chdir(path) == 0) {
    lua_pushnil(L);
    lua_pushstring(L, "ok");
  } else {
    lua_pushinteger(L, errno);
    lua_pushstring(L, strerror(errno));
  }
  return 2;
}

static const luaL_Reg ccpkglib[] = {
  { "chdir", ccpkg_chdir },
  { "getcwd", ccpkg_getcwd },
  /* placeholders */
  { NULL, NULL }
};

/*
** Open ccpkg library
*/
LUAMOD_API int luaopen_ccpkg (lua_State *L) {
  luaL_newlib(L, ccpkglib);
  return 1;
}
