#include <fstream>
#include <filesystem>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

namespace fs = std::filesystem;

struct TestFixture {
  const char *filename = "/tmp/test.lua";
  lua_State *L;
  TestFixture();
  ~TestFixture();
  int run(const std::string &code);
  std::string error();
  std::string type(const char *name);
  std::string value(const char *name);
  std::string value(const char *name, const char *field);
};
