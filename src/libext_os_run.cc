#include <lua.hpp>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <filesystem>
#include <boost/process.hpp>

namespace fs = std::filesystem;
namespace bp = boost::process;

struct Dispatcher {
  int mode;
  const char *cmd;
  const char *exe;
  std::string out_file;
  std::string start_dir;
  bp::environment env;
  std::vector<std::string> args;

  bp::ipstream ips_out;
  bp::ipstream ips_err;

  explicit Dispatcher(void)
  : cmd(nullptr), exe(nullptr), mode(0)
  , env(boost::this_process::environment()) {
  }
  ~Dispatcher(void) = default;
  Dispatcher(const Dispatcher&) = delete;
  Dispatcher(Dispatcher &&) = delete;
  Dispatcher& operator=(const Dispatcher&) = delete;
  Dispatcher& operator=(Dispatcher &&) = delete;

  int dispatch(lua_State *L) {
    int exit_code = (cmd ? cmd_style(L) : exe_args_style(L));

    if (exit_code == 0) {
      lua_pushboolean(L, 1);
    } else {
      lua_pushnil(L);
    }

    lua_newtable(L);
    lua_pushinteger(L, exit_code);
    lua_setfield(L, -2, "exit_code");

    if (mode == 1) {
      push_pstream_result(L, ips_out);
      lua_setfield(L, -2, "stdout");

      push_pstream_result(L, ips_err);
      lua_setfield(L, -2, "stderr");
    }

    return 2;
  }

  int cmd_style(lua_State *L) {
    int exit_code;

    try {
      switch (mode) {
      case 1:
        exit_code = bp::system(cmd, env, bp::start_dir=start_dir, bp::std_out > ips_out, bp::std_err > ips_err);
        break;
      case 2:
        do {
          FILE *fp = fopen(out_file.c_str(), "w+");
          if (fp == NULL) {
            luaL_error(L, "fopen output file failed: %s", strerror(errno));
          }
          exit_code = bp::system(cmd, env, bp::start_dir=start_dir, bp::std_out > fp, bp::std_err > fp);
          fclose(fp);
        } while (0);
        break;
      default:
        exit_code = bp::system(cmd, env, bp::start_dir=start_dir, bp::std_out > bp::null, bp::std_err > bp::null);
        break;
      }
    } catch (const std::exception &e) {
      luaL_error(L, "error: %s", e.what());
    }

    return exit_code;
  }

  int exe_args_style(lua_State *L) {
    int exit_code;

    try {
      switch (mode) {
      case 1:
        exit_code = bp::system(exe, bp::args=args, bp::env=env, bp::start_dir=start_dir, bp::std_out > ips_out, bp::std_err > ips_err);
        break;
      case 2:
        do {
          FILE *fp = fopen(out_file.c_str(), "w+");
          if (fp == NULL) {
            luaL_error(L, "fopen output file failed: %s", strerror(errno));
          }
          exit_code = bp::system(exe, bp::args=args, bp::env=env, bp::start_dir=start_dir, bp::std_out > fp, bp::std_err > fp);
          fclose(fp);
        } while (0);
        break;
      default:
        exit_code = bp::system(exe, bp::args=args, bp::env=env, bp::start_dir=start_dir, bp::std_out > bp::null, bp::std_err > bp::null);
        break;
      }
    } catch (const std::exception &e) {
      luaL_error(L, "error: %s", e.what());
    }

    return exit_code;
  }

  void push_pstream_result(lua_State *L, bp::ipstream &is) {
    std::string line, data;
    while ( std::getline(is, line) && !line.empty() ) {
      if (data.empty()) {
        data = line;
      } else {
        data += "\n";
        data += line;
      }
    }

    if ( data.empty() ) {
      lua_pushstring(L, "");
    } else {
      lua_pushstring(L, data.data());
    }
  }
};

LUALIB_API int ext_os_run(lua_State *L) {
  int t = 0;
  Dispatcher d;
  luaL_checktype(L, 1, LUA_TTABLE);

  lua_getfield(L, 1, "cmd");
  if (lua_isstring(L, -1)) {
    d.cmd = lua_tostring(L, -1);
  }

  lua_getfield(L, 1, "exe");
  if (lua_isstring(L, -1)) {
    d.exe = lua_tostring(L, -1);
  }

  if (d.cmd == nullptr && d.exe == nullptr) {
    luaL_error(L, "one of `cmd` or `exe` is needed");
  }

  lua_getfield(L, 1, "start_dir");
  if (lua_type(L, -1) == LUA_TSTRING) {
    const char *s = lua_tostring(L, -1);
    auto p = fs::path(s);
    if (p.has_relative_path() || p.has_root_path()) {
      d.start_dir = s;
    } else {
      luaL_error(L, "invalid start_dir: %s", s);
    }
  } else {
    d.start_dir = fs::current_path();
  }

  lua_getfield(L, 1, "out");
  if (lua_type(L, -1) == LUA_TSTRING) {
    size_t len = 0;
    const char *s = lua_tolstring(L, -1, &len);

    if ( len == 0 ) {
      d.mode = 0;
    } else if ( strcmp(s, "capture") == 0 ) {
      d.mode = 1;
    } else {
      auto p = fs::path(s);
      if (p.extension() != "" || p.has_root_path() || p.has_relative_path()) {
        d.mode = 2;
        d.out_file = s;
      } else {
        luaL_error(L, "invalid out option: `capture` or path expected, got %s", s);
      }
    }
  } else if (lua_type(L, -1) == LUA_TNIL) {
    d.mode = 0;
  } else {
    luaL_error(L, "bad option `out`: string expected, got %s", luaL_typename(L, lua_type(L, -1)));
  }
  lua_pop(L, 1);

  if (d.exe) {
    lua_getfield(L, 1, "args");
    if (lua_istable(L, -1)) {
      t = lua_gettop(L);
      int n = luaL_len(L, t);
      for (int i = 1; i <= n; ++i) {
        lua_geti(L, t, i);
        if (lua_isstring(L, -1)) {
          d.args.push_back(lua_tostring(L, -1));
        } else {
          luaL_error(L, "bad element #%d: string expected, got %s", i, luaL_typename(L, lua_type(L, -1)));
        }
        lua_pop(L, 1);
      }
    } else {
      luaL_error(L, "bad argument #args: table expected, got %s", luaL_typename(L, lua_type(L, -1)));
    }
    lua_pop(L, 1); /* remove args from stack */
  }

  lua_getfield(L, 1, "envs");
  if (lua_istable(L, -1)) {
    t = lua_gettop(L);
    lua_pushnil(L);  /* first key */
    while (lua_next(L, t) != 0) {
      /* uses 'key' (at index -2) and 'value' (at index -1) */
      if (lua_isstring(L, -2)) {
        const char *key = lua_tostring(L, -2);
        if (lua_istable(L, -1)) {
          int n = luaL_len(L, -1);
          for (int i = 1; i <= n; ++i) {
            lua_geti(L, -1, i);
            if (i == 1) {
              d.env[key] = lua_tostring(L, -1);
            } else {
              d.env[key] += lua_tostring(L, -1);
            }
            lua_pop(L, 1);
          }
        } else {
          d.env[key] = lua_tostring(L, -1);
        }
      }
      lua_pop(L, 1); /* removes 'value'; keeps 'key' for next iteration */
    }
  }
  lua_pop(L, 1); /* remove envs from stack */

  return d.dispatch(L);
}
