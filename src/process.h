#ifndef __CCPKG_PROCESS_H
#define __CCPKG_PROCESS_H
#include <string>
#include <vector>
#include <map>
#include "lua.h"

namespace process {
class Process {
  static int n_instance;

  std::string cwd;
  std::string exe;
  std::string cmd;
  std::string file;
  bool shell = false;
  bool check = false;
  bool capture_output = false;
  std::vector<std::string> args;
  std::map<std::string, std::string> envs;

  int child_pid;
  int waitpid_status;
  int stdout_pipefd[2];
  int stderr_pipefd[2];

  int  fork_parent(lua_State *L);
  void fork_child(void);
  bool child_is_running(lua_State *L);
  int  wait_child(lua_State *L);
  std::string which(lua_State *L, const std::string &name);

public:
  Process();
  Process(const Process&) = delete;
  Process(Process&&) = delete;
  Process& operator=(const Process&) = delete;
  Process& operator=(Process&&) = delete;
  ~Process();

  void init(lua_State *L);
  int  exec(lua_State *L);
};

}
#endif /* __CCPKG_PROCESS_H */
