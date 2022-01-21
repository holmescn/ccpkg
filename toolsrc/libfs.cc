/*
** $Id: libfs.cc $
** filesystem library
*/

#include <filesystem>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

namespace fs = std::filesystem;

static int fs_copyfile(lua_State *L) {
  const char* f = luaL_checkstring(L, 1);
  const char* t = luaL_checkstring(L, 2);
  const auto copyOptions = fs::copy_options::update_existing;

  try {
    fs::copy_file(f, t, copyOptions);
  } catch (const std::exception &e) {
    luaL_error(L, "copy %s to %s failed: %s", f, t, e.what());
  }

  lua_pushboolean(L, true);
  return 1;
}

static int fs_fuzzyfind(lua_State *L) {
  int i = 0;
  std::string path = luaL_checkstring(L, 1);
  std::string name = luaL_checkstring(L, 2);
  for(auto const& entry: std::filesystem::directory_iterator{path}) {
  }

  lua_pushnil(L);
  return 1;
}

static int fs_listdir(lua_State *L) {
  int i = 0;
  std::string path = luaL_checkstring(L, 1);
  lua_newtable(L);
  for(auto const& entry: std::filesystem::directory_iterator{path}) {
    std::string s = entry.path();
    s = s.substr(path.size() + 1);
    lua_pushstring(L, s.data());
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

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

static const luaL_Reg fslib[] = {
  { "mkdirs", fs_mkdirs },
  { "exists", fs_exists },
  { "listdir", fs_listdir },
  { "fuzzyfind", fs_fuzzyfind },
  { "copyfile", fs_copyfile },
  { NULL, NULL }
};

/*
** Open fs library
*/
LUAMOD_API int luaopen_fs (lua_State *L) {
  luaL_newlib(L, fslib);
  return 1;
}
