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

/**
 * @brief guess OS name from environment
 * 
 * @return const char* 
 */
const char *guess_os(void) {
  // TODO Guess OS name from environment
  return "linux";
}

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

static int os_listdir(lua_State *L) {
  luaL_checktype(L, 1, LUA_TSTRING);
  const char *s = luaL_checkstring(L, 1);
  lua_createtable(L, 0, 0);

  int i = 0;
  for (const auto& dir_entry : std::filesystem::directory_iterator{s}) {
    lua_pushstring(L, dir_entry.path().c_str());
    lua_seti(L, -2, ++i);
  }

  return 1;
}

struct copy_option_entry {
  const char *name;
  fs::copy_options option;
};

struct copy_option_entry copy_option_list[] = {
  { "skip", fs::copy_options::skip_existing },
  { "overwrite", fs::copy_options::overwrite_existing },
  { "update", fs::copy_options::update_existing },
  { "recursive", fs::copy_options::recursive },
  { "recursive", fs::copy_options::recursive }
};

static int os_copy(lua_State *L) {
  luaL_checktype(L, 1, LUA_TSTRING);
  luaL_checktype(L, 2, LUA_TSTRING);
  luaL_checktype(L, 3, LUA_TTABLE);
  const char *src = luaL_checkstring(L, 1);
  const char *dst = luaL_checkstring(L, 2);
  auto option = fs::copy_options::none;

  for (int i = 0; i < sizeof(copy_option_list)/sizeof(copy_option_entry); ++i) {
    lua_getfield(L, 3, copy_option_list[i].name);
    if (lua_type(L, -1) != LUA_TNIL) {
      option |= copy_option_list[i].option;
    }
    lua_pop(L, 1);
  }

  try {
    fs::copy(src, dst, option);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int os_copyfile(lua_State *L) {
  luaL_checktype(L, 1, LUA_TSTRING);
  luaL_checktype(L, 2, LUA_TSTRING);
  const char *src = luaL_checkstring(L, 1);
  const char *dst = luaL_checkstring(L, 2);
  auto option = fs::copy_options::overwrite_existing;
  try {
    fs::copy_file(src, dst, option);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static const luaL_Reg ext_os[] = {
  { "run", os_run },
  { "chdir", os_chdir },
  { "mkdirs", os_mkdirs },
  { "rmdirs", os_rmdirs },
  { "curdir", os_curdir },
  { "listdir", os_listdir },
  { "copy", os_copy },
  { "copyfile", os_copyfile },
  { NULL, NULL }
};

static int os_path_join (lua_State *L) {
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

static int os_path_exists (lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  lua_pushboolean(L, (s ? fs::exists(s) : false));
  return 1;
}

static const luaL_Reg os_path[] = {
  { "join", os_path_join },
  { "exists", os_path_exists },
  { NULL, NULL }
};

/*
** extend os library
*/
LUAMOD_API int luaext_os (lua_State *L) {
  lua_getglobal(L, "os");

  for (const luaL_Reg *entry = ext_os; entry->func; ++entry) {
    lua_pushcfunction(L, entry->func);
    lua_setfield(L, -2, entry->name);
  }

  lua_pushstring(L, guess_os());
  lua_setfield(L, -2, "name");

  lua_createtable(L, 0, sizeof(os_path)/sizeof(os_path[0]));
  for (const luaL_Reg *entry = os_path; entry->func; ++entry) {
    lua_pushcfunction(L, entry->func);
    lua_setfield(L, -2, entry->name);
  }
  lua_setfield(L, -2, "path");

  lua_pop(L, 1);

  return 0;
}
