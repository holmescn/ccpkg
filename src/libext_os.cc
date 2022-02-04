/*
** $Id: libext_os.cc $
** ext os library
*/
#include <lua.h>
#include "lualib.h"
#include "lauxlib.h"

#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <boost/process.hpp>

namespace fs = std::filesystem;
namespace bp = boost::process;

LUALIB_API void luaopen_ext_os_path(lua_State *L);
LUALIB_API int ext_os_run(lua_State *L);

/**
 * @brief guess OS name from environment
 * 
 * @return const char* 
 */
static const char *guess_os(void) {
  // TODO Guess OS name from environment
  return "linux";
}

static int ext_os_curdir(lua_State *L) {
  auto dir = fs::current_path();
  lua_pushstring(L, dir.c_str());
  return 1;
}

static int ext_os_mkdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  try {
    fs::create_directories(s);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int ext_os_rmdirs(lua_State *L) {
  const char *s = luaL_checkstring(L, 1);
  try {
    fs::remove_all(s);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int ext_os_listdir(lua_State *L) {
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
  auto options = opt_copy_options(L, 3);

  try {
    fs::copy(src, dst, options);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int ext_os_copyfile(lua_State *L) {
  const char *src = luaL_checkstring(L, 1);
  const char *dst = luaL_checkstring(L, 2);
  auto options = opt_copy_options(L, 3);

  try {
    fs::copy_file(src, dst, options);
  } catch (const std::exception &e) {
    luaL_error(L, "error: %s", e.what());
  }
  return 0;
}

static int ext_os_searchpath(lua_State *L) {
  const char *exe = luaL_checkstring(L, 1);
  try {
    auto p = bp::search_path(exe);
    if (p.empty()) {
      lua_pushnil(L);
    } else {
      lua_pushstring(L, p.c_str());
    }
  } catch (const std::exception &e) {
    luaL_error(L, "search_path failed: %s", e.what());
  }
  return 1;
}

static const luaL_Reg ext_os[] = {
  { "run", ext_os_run },
  { "mkdirs", ext_os_mkdirs },
  { "rmdirs", ext_os_rmdirs },
  { "curdir", ext_os_curdir },
  { "listdir", ext_os_listdir },
  { "copy", ext_os_copy },
  { "copyfile", ext_os_copyfile },
  { "search_path", ext_os_searchpath },
  { NULL, NULL }
};

/*
** extend os library
*/
LUAMOD_API void luaopen_ext_os (lua_State *L) {
  lua_getglobal(L, "os");

  luaL_setfuncs(L, ext_os, 0);
  lua_pushstring(L, guess_os());
  lua_setfield(L, -2, "name");

  luaopen_ext_os_path(L);

  lua_pop(L, lua_gettop(L));
}
