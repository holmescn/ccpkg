/*
** $Id: libext_os.cc$
** extend os library
*/
#include <lua.h>
#include "lualib.h"
#include "lauxlib.h"
#include "luaconf.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <queue>
#include <string>
#include <vector>
#include <sstream>
#include <filesystem>
#include "process.h"

namespace fs = std::filesystem;

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define THROW_LUA_ERROR \
error:                   \
  luaL_error(L, "%s", lua_tostring(L, -1)); \
  return 0;

/*
** ===================================================================
** extend os.* functions
** ===================================================================
*/

/*
** python subprocess.run clone
*/
static int ext_os_run(lua_State *L) {
  using namespace process;

  int rv = 0;

  {
    Process p;
    try {
      p.init(L);
    } catch (const std::runtime_error &) {
      goto error;
    }

    try {
      rv = p.exec(L);
    } catch (const std::runtime_error &) {
      goto error;
    }
  } /* C++ objects are cleaned up here */
  return rv;

  THROW_LUA_ERROR;
}

static int ext_os_curdir(lua_State *L) {
  {
    auto dir = fs::current_path();
    lua_pushstring(L, dir.c_str());
  }
  return 1;
}

static int ext_os_mkdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);

  {
    try {
      lua_pushboolean(L, fs::create_directories(s));
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* C++ objects are cleaned up here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_rmdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);

  {
    try {
      lua_pushinteger(L, fs::remove_all(s));
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_listdir(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);

  {
    auto start = fs::path(s);
    try {
      int i = 0;
      lua_newtable(L);
      for (const auto& dir_entry : std::filesystem::directory_iterator{start}) {
        const auto p = fs::relative(dir_entry.path(), start);
        lua_pushstring(L, p.c_str());
        lua_seti(L, -2, ++i);
      }
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  }
  return 1;

  THROW_LUA_ERROR;
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
  { "copy_symlinks", fs::copy_options::copy_symlinks },
  { "skip_symlinks", fs::copy_options::skip_symlinks },
  { "create_symlinks", fs::copy_options::create_symlinks },
  { "directories_only", fs::copy_options::directories_only },
  { "create_hard_links", fs::copy_options::create_hard_links }
};

static fs::copy_options opt_copy_options(lua_State *L, int arg) {
  auto options = fs::copy_options::none;

  if (lua_type(L, arg) != LUA_TTABLE) return options;

  for (int i = 0; i < sizeof(copy_option_list)/sizeof(copy_option_entry); ++i) {
    lua_getfield(L, arg, copy_option_list[i].name);
    if (lua_toboolean(L, -1)) {
      options |= copy_option_list[i].option;
    }
    lua_pop(L, 1);
  }
  return options;
}

static int ext_os_copy(lua_State *L) {
  const char *src = luaL_checkstring(L, 1);
  const char *dst = luaL_checkstring(L, 2);

  {
    auto options = opt_copy_options(L, 3);
    try {
      fs::copy(src, dst, options);
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed. */
  return 0;

  THROW_LUA_ERROR;
}

static int ext_os_copyfile(lua_State *L) {
  const char *src = luaL_checkstring(L, 1);
  const char *dst = luaL_checkstring(L, 2);

  {
    auto options = opt_copy_options(L, 3);
    try {
      lua_pushboolean(L, fs::copy_file(src, dst, options));
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objecs are destructed. */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_which(lua_State *L) {
  const char *delimiters = ":";
  const char *exe = luaL_checkstring(L, 1);
  const char *PATH = getenv("PATH");

  if (PATH == nullptr) {
    luaL_error(L, "$PATH variable is not found");
  }

  {
    std::string buffer(PATH);
    char *token = std::strtok(buffer.data(), delimiters);
    while (token) {
      auto full_path = fs::path(token) / exe;
      if (fs::exists(full_path)) {
        lua_pushstring(L, full_path.c_str());
        break;
      }
      token = std::strtok(nullptr, delimiters);
    }
    if (!token) {
      lua_pushnil(L);
    }
  } /* C++ objects are cleaned up here. */

  return 1;
}

static int ext_os_walk(lua_State *L) {
  typedef std::queue<std::string> dir_queue_t;
  int rv = 3;

  if (lua_type(L, 1) == LUA_TSTRING) {
    /* initial: local f, s, var = explist */
    void *place;
    const char *root = luaL_checkstring(L, 1);
    lua_pushcfunction(L, ext_os_walk);
    place = lua_newuserdata(L, sizeof(dir_queue_t));
    luaL_getmetatable(L, "std::queue");
    lua_setmetatable(L, -2);

    dir_queue_t *q = new (place) dir_queue_t();
    q->push(root);
    lua_pushstring(L, root);
  } else {
    void *ud = luaL_checkudata(L, 1, "std::queue");
    dir_queue_t *q = reinterpret_cast<dir_queue_t*>(ud);
    luaL_argcheck(L, ud != NULL, 1, "`std::queue' expected");

    /**
     * while true do
     *   local var_1, ···, var_n = f(s, var)
     *   if var_1 == nil then break end
     *   var = var_1
     *   block
     * end
     * 
     * note: the var is ignored here
     */

    if (q->empty()) {
      rv = 1;
      lua_pushnil(L);
      q->~dir_queue_t();
    } else {
      auto root = q->front(); q->pop();
      lua_pushstring(L, root.c_str());
      try {
        int i_file = 0, i_dir = 0;
        lua_newtable(L); /* dirs */
        lua_newtable(L); /* files */
        for (const auto& dir_entry : std::filesystem::directory_iterator{root}) {
          const auto p = fs::relative(dir_entry.path(), root);
          lua_pushstring(L, p.c_str());
          if (dir_entry.is_directory()) {
            lua_seti(L, -3, ++i_dir);

            /* push the dir */
            q->push(dir_entry.path());
          } else {
            lua_seti(L, -2, ++i_file);
          }
        }
      } catch (const std::exception &e) {
        lua_pushstring(L, e.what());
        goto error;
      }
    }
  }
  return rv;

  THROW_LUA_ERROR;
}

/*
** ===================================================================
** extend os.path.* functions like python.
** ===================================================================
*/

static int ext_os_path_join (lua_State *L) {

  {
    fs::path p;

    /* table-based argument */
    if ( lua_type(L, 1) == LUA_TTABLE ) {
      int n = luaL_len(L, 1);
      for (int i = 1; i <= n; ++i) {
        if (lua_geti(L, 1, i) == LUA_TSTRING) {
          if (i == 1) {
            p = lua_tostring(L, -1);
          } else {
            p /= lua_tostring(L, -1);
          }
        } else {
          lua_pushfstring(L, "bad element #%d in argument #1 to 'join' (string expected, got %s)", i, luaL_typename(L, -1));
          goto error;
        }
        lua_pop(L, 1);
      }
    } else {
      int n = lua_gettop(L);
      for (int i = 1; i <= n; ++i) {
        if (lua_type(L, i) == LUA_TSTRING) {
          if (i == 1) {
            p = lua_tostring(L, i);
          } else {
            p /= lua_tostring(L, i);
          }
        } else {
          lua_pushfstring(L, "bad argument #%d to 'join' (string expected, got %s)", i, luaL_typename(L, -1));
          goto error;
        }
      }
    }

    if (p.empty()) {
      lua_pushstring(L, "");
    } else {
      lua_pushstring(L, p.c_str());
    }
  } /* C++ objects are destructed here. */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_exists (lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  lua_pushboolean(L, (s ? fs::exists(s) : false));
  return 1;
}

static int ext_os_path_abspath (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  {
    try {
      std::string s = fs::weakly_canonical(path);
      lua_pushstring(L, s.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_relpath (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  {
    std::string start = fs::current_path();
    if (lua_type(L, 2) == LUA_TSTRING) {
      start = lua_tostring(L, 2);
    }

    try {
      fs::path r = fs::relative(path, start);
      lua_pushstring(L, r.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_realpath (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  {
    try {
      std::string s = fs::canonical(path);
      lua_pushstring(L, s.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_basename (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  {
    try {
      std::string s = fs::path(path).filename();
      lua_pushstring(L, s.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_dirname (lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  {
    try {
      std::string s = fs::path(path).remove_filename();
      if (s.back() == '/') {
        s.back() = '\0';
      }
      lua_pushstring(L, s.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 1;

  THROW_LUA_ERROR;
}

static int ext_os_path_splitext (lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);

  {
    try {
      std::string stem = fs::path(filename).stem();
      std::string ext = fs::path(filename).extension();
      lua_pushstring(L, stem.c_str());
      lua_pushstring(L, ext.c_str());
    } catch (const std::exception &e) {
      lua_pushstring(L, e.what());
      goto error;
    }
  } /* c++ objects are destructed here */
  return 2;

  THROW_LUA_ERROR;
}

static int ext_os_path_files (lua_State *L) {
  const char *s = luaL_checkstring(L, 1);

  {
    auto start = fs::path(s);
    try {
      int i = 0;
      lua_newtable(L);
      for (auto const& dir_entry : fs::recursive_directory_iterator(start)) {
        if (dir_entry.is_directory()) continue;
        const auto p = fs::relative(dir_entry.path(), start);
        lua_pushstring(L, p.c_str());
        lua_seti(L, -2, ++i);
      }
    } catch (const std::exception &e) {
      // nothing to do, just return empty table
    }
  }
  return 1;
}

/*
** extend os library
*/
LUAMOD_API void luaext_os (lua_State *L) {
  const luaL_Reg ext_os[] = {
    { "run", ext_os_run },
    { "mkdirs", ext_os_mkdirs },
    { "rmdirs", ext_os_rmdirs },
    { "curdir", ext_os_curdir },
    { "listdir", ext_os_listdir },
    { "copy", ext_os_copy },
    { "copyfile", ext_os_copyfile },
    { "which", ext_os_which },
    { "walk", ext_os_walk },
    { NULL, NULL }
  };

  const luaL_Reg ext_os_path[] = {
    { "join", ext_os_path_join },
    { "exists", ext_os_path_exists },
    { "abspath", ext_os_path_abspath },
    { "relpath", ext_os_path_relpath },
    { "realpath", ext_os_path_realpath },
    { "basename", ext_os_path_basename },
    { "dirname", ext_os_path_dirname },
    { "splitext", ext_os_path_splitext },
    { "files", ext_os_path_files },
    { NULL, NULL }
  };

  luaL_newmetatable(L, "std::queue");

  lua_getglobal(L, "os");

  luaL_setfuncs(L, ext_os, 0);
  lua_pushstring(L, "posix");
  lua_setfield(L, -2, "name");
  lua_pushstring(L, ":");
  lua_setfield(L, -2, "pathsep");

  lua_createtable(L, 0, ARRAY_SIZE(ext_os_path));
  luaL_setfuncs(L, ext_os_path, 0);
  lua_pushstring(L, LUA_DIRSEP);
  lua_setfield(L, -2, "sep");
  lua_pushstring(L, ":");
  lua_setfield(L, -2, "pathsep");
  lua_setfield(L, -2, "path");

  lua_pop(L, lua_gettop(L));
}
