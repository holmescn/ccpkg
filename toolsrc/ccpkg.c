/*
** $Id: ccpkg.cc $
** ccpkg library
*/
#include <stdlib.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static const luaL_Reg ccpkglib[] = {
  { "root_dir", NULL },
  { NULL, NULL }
};

/*
** Open ccpkg library
*/
LUAMOD_API int luaopen_ccpkg (lua_State *L) {
  luaL_newlib(L, ccpkglib);
  lua_pushstring(L, getenv("CCPKG_ROOT"));
  lua_setfield(L, -2, "root_dir");
  return 1;
}
