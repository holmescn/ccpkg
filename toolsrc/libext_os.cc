/*
** $Id: libext_os.cc $
** ext os library
*/
#include <cstdlib>
#include <cstring>
#include <filesystem>

#include <lua.h>
#include "lualib.h"
#include "lauxlib.h"

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>

namespace fs = std::filesystem;

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof(arr[0]))
static char *ARGS[128];
static char *ENVS[128];

static int check_and_unwind(lua_State *L, const char *field, int idx) {
  int n = luaL_len(L, idx);
  for (int i = 0; i < n; ++i) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, idx);
    if ( lua_type(L, -1) != LUA_TSTRING) {
      const char *tname = lua_typename(L, lua_type(L, -1));
      lua_settop(L, idx);
      return luaL_error(L, "bad element #%d of `%s`: string expected, got %s", i+1, field, tname);
    }
  }
  return lua_gettop(L);
}

static int os_run(lua_State *L) {
  int args_idx = 0, envs_idx = 0;
  int args_b = 0, args_e = 0;
  int envs_b = 0, envs_e = 0;
  const char *cmd = NULL, *out = NULL;
  pid_t pid;
  int status;

  /* discard any extra arguments passed in */
  lua_settop(L, 1);
  luaL_checktype(L, 1, LUA_TTABLE);

  /* command */
  lua_getfield(L, 1, "cmd");
  if ( lua_type(L, -1) != LUA_TSTRING ) {
    return luaL_error(L, "bad field `cmd`: string expected, got %s", lua_typename(L, lua_type(L, -1)));
  }
  cmd = lua_tostring(L, -1);

  /* out */
  lua_getfield(L, 1, "out");
  if ( lua_type(L, -1) == LUA_TSTRING ) {
    out = lua_tostring(L, -1);
  } else if ( lua_type(L, -1) != LUA_TNIL ) {
    return luaL_error(L, "bad field `out`: string expected, got %s", lua_typename(L, lua_type(L, -1)));
  }

  /* args */
  lua_getfield(L, 1, "args");
  if ( lua_type(L, -1) != LUA_TTABLE ) {
    return luaL_error(L, "bad field `args`: table expected, got %s", lua_typename(L, lua_type(L, -1)));
  }
  args_idx = lua_gettop(L);

  lua_getfield(L, 1, "envs");
  if ( lua_type(L, -1) == LUA_TTABLE ) {
    envs_idx = lua_gettop(L);
  } else if (lua_type(L, -1) != LUA_TNIL) {
    return luaL_error(L, "bad field `envs`: table expected, got %s", lua_typename(L, lua_type(L, -1)));
  }

  args_b = args_idx + 2;
  args_e = check_and_unwind(L, "args", args_idx);

  if (envs_idx > 0) {
    envs_b = args_e + 1;
    envs_e = check_and_unwind(L, "envs", envs_idx);
  }

  for (int i = 0; i < ARRAY_SIZE(ARGS); ++i) {
    ARGS[i] = NULL;
  }

  for (int i = 0; i < ARRAY_SIZE(ENVS); ++i) {
    ENVS[i] = NULL;
  }

  for (int i = args_b, k= 0; i <= args_e && i < ARRAY_SIZE(ARGS); ++i, ++k) {
    ARGS[k] = (char*)lua_tostring(L, i);
  }

  if (envs_idx > 0) {
    for (int i = envs_b, k = 0; i <= envs_e && i < ARRAY_SIZE(ENVS); ++i, ++k) {
      ENVS[k] = (char*)lua_tostring(L, i);
    }
  }

  /* POSIX */
  pid = fork();
  if (pid < 0) {
    perror("fork");
  } else if (pid == 0) {
    if (out) {
      int fd = open(out, O_RDWR|O_CREAT|O_CLOEXEC);
      if (fchmod(fd, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH) == -1) {
        perror("fchmod");
      }
      for (int i = 0; i < 3; ++i) {
        if (dup2(fd, STDOUT_FILENO) != -1) break;
        perror("dup2(fd, STDOUT_FILENO)");
      }
      for (int i = 0; i < 3; ++i) {
        if (dup2(fd, STDERR_FILENO) != -1) break;
        perror("dup2(fd, STDERR_FILENO)");
      }
    }
    execve(cmd, ARGS, ENVS);
    perror(cmd);
    exit(errno);
  }

  pid = wait(&status);
  lua_pushinteger(L, WEXITSTATUS(status));
  if (WIFEXITED(status)) {
    lua_pushstring(L, "exit");
  } else if (WIFSIGNALED(status)) {
    lua_pushstring(L, "signal");
  }

  return 2;
}

static int os_chdir(lua_State *L) {
  const char *dir = luaL_checkstring(L, 1);
  if ( chdir(dir) != 0) {
    luaL_error(L, "chdir failed: %s", strerror(errno));
  }
  return 0;
}

static int os_curdir(lua_State *L) {
  auto dir = fs::current_path();
  lua_pushstring(L, dir.c_str());
  return 1;
}

static int os_mkdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  try {
    fs::create_directories(s);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int os_rmdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  try {
    fs::remove_all(s);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
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

static const luaL_Reg ext_os_lib[] = {
  { "run", os_run },
  { "chdir", os_chdir },
  { "mkdirs", os_mkdirs },
  { "rmdirs", os_rmdirs },
  { "curdir", os_curdir },
  { NULL, NULL }
};

/*
** extend os library
*/
LUAMOD_API int luaext_os (lua_State *L) {
  lua_getglobal(L, "os");

  for (const luaL_Reg *entry = ext_os_lib; entry->func; ++entry) {
    lua_pushcfunction(L, entry->func);
    lua_setfield(L, -2, entry->name);
  }

  lua_pushstring(L, guess_os());
  lua_setfield(L, -2, "name");

  lua_pop(L, 1);

  return 0;
}
