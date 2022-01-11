#include <stdio.h>
#include <stdlib.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static void tbl_setvalue(lua_State *L, const char *key, const char *value)
{
  lua_pushstring(L, key);
  lua_pushstring(L, value);
  lua_settable(L, -3);
}

int main(int argc, char *argv[]) {
  const char *ccpkg_root;
  lua_State *L;

  ccpkg_root = getenv("CCPKG_ROOT");
  if (ccpkg_root == NULL) {
    fprintf(stderr, "Please set $CCPKG_ROOT.\n");
    return -1;
  }

  L = luaL_newstate();
  luaL_openlibs(L);

  lua_newtable(L);
  tbl_setvalue(L, "sep", "/");
  tbl_setvalue(L, "root", ccpkg_root);

  // luaL_setfuncs(L, &MyMathLib, 0);
  lua_setglobal(L, "ccpkg");

  if (luaL_dostring(L, "print(LUA_PATH)") == LUA_OK) {
    lua_pop(L, lua_gettop(L));
  }

  lua_close(L);

  return 0;
}
