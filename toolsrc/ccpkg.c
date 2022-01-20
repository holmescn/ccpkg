/*
** $Id: ccpkg.cc $
** ccpkg library
*/
#include <lua.h>
#include "lualib.h"
#include "lauxlib.h"

static const luaL_Reg ccpkglib[] = {
  { NULL, NULL }
};

/*
** Open path library
*/
LUAMOD_API int luaopen_ccpkg (lua_State *L) {
  luaL_newlib(L, ccpkglib);
  return 1;
}
