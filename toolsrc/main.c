#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define LUA_PROGNAME "ccpkg"

LUALIB_API int ext_os_run (lua_State *L);
LUAMOD_API int luaopen_fs (lua_State *L);
LUAMOD_API int luaopen_path (lua_State *L);
LUAMOD_API int luaopen_ccpkg (lua_State *L);

static const char *progname = LUA_PROGNAME;

/*
** Prints an error message, adding the program name in front of it
** (if present)
*/
static void l_message (const char *pname, const char *msg) {
  if (pname) lua_writestringerror("%s: ", pname);
  lua_writestringerror("%s\n", msg);
}

/*
** Create the 'ARGS' table, which stores all arguments from the
** command line ('argv'). It should be aligned so that, at index 0,
** it has 'argv[script]', which is the script name. The arguments
** to the script (everything after 'script') go to positive indices;
** other arguments (before the script name) go to negative indices.
** If there is no script name, assume interpreter's name as base.
*/
static void createargtable (lua_State *L, int argc, char **argv) {
  lua_createtable(L, argc - 1, 0);
  for (int i = 1; i < argc; ++i) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "ARGS");
}

/**
 * @brief guess OS name from environment
 * 
 * @return const char* 
 */
const char *guess_os(void) {
  // TODO Guess OS name from environment
  return "linux";
}
/* }================================================================== */

int main (int argc, char **argv) {
  lua_State *L;
  char script[1024];
  const char *ccpkg_root = getenv("CCPKG_ROOT");
  if (ccpkg_root == NULL) {
    l_message(progname, "please set $CCPKG_ROOT");
    return EXIT_FAILURE;
  }

  L = luaL_newstate();  /* create state */
  if (L == NULL) {
    l_message(progname, "cannot create state: not enough memory");
    return EXIT_FAILURE;
  }

  luaL_checkversion(L);  /* check that interpreter has correct version */
  luaL_openlibs(L);

  /* extra modules */
  luaL_requiref(L, "fs", luaopen_fs, 1);
  luaL_requiref(L, "path", luaopen_path, 1);
  luaL_requiref(L, "ccpkg", luaopen_ccpkg, 1);
  lua_pop(L, 3);

  lua_pushstring(L, ccpkg_root);
  lua_setglobal(L, "CCPKG_ROOT_DIR");

  /* extend os module */
  lua_getglobal(L, "os");
  lua_pushstring(L, guess_os());
  lua_setfield(L, -2, "name");
  lua_pushcfunction(L, ext_os_run);
  lua_setfield(L, -2, "run");
  lua_pop(L, lua_gettop(L));

  createargtable(L, argc, argv);

  if (luaL_dostring(L, "PROJECT_DIR = fs.currentdir()") != LUA_OK) {
    fprintf(stderr, "%s\n", lua_tostring(L, lua_gettop(L)));
    lua_pop(L, lua_gettop(L));
  }

  snprintf(script, sizeof(script), "%s/scripts/init.lua", ccpkg_root);
  if (luaL_dofile(L, script) != LUA_OK) {
    fprintf(stderr, "%s\n", lua_tostring(L, lua_gettop(L)));
    lua_pop(L, lua_gettop(L));
  }

  lua_close(L);
  return EXIT_SUCCESS;
}
