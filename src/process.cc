/*
** A python subprocess.run like executor
*/
#include <cstdio>
#include <cstring>
#include <array>
#include <sstream>
#include <filesystem>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "process.h"

using namespace process;
namespace fs = std::filesystem;

int Process::n_instance = 0;
extern char **environ;

Process::Process() {
  if (n_instance++ > 0) throw std::runtime_error("some instances are not destructed.");

  for (int i = 0; environ[i]; ++i) {
    const char *b = environ[i];
    const char *e = std::strchr(environ[i], '=');
    envs[std::string(b, e)] = environ[i];
  }

  child_pid = -1;
  waitpid_status = -1;
  stdout_pipefd[0] = -1;
  stdout_pipefd[1] = -1;
  stderr_pipefd[0] = -1;
  stderr_pipefd[1] = -1;
  cwd = fs::current_path();
}

Process::~Process() {
  n_instance -= 1;
}

void Process::init(lua_State *L) {
  /* argument #1 */
  if (lua_type(L, 1) == LUA_TSTRING) {
    std::string cmd = lua_tostring(L, 1);
    if (cmd.size() == 0) {
      lua_pushstring(L, "bad argument #1 to 'run' (length should > 0)");
      throw std::runtime_error(lua_tostring(L, -1));
    }

    char *token = std::strtok(cmd.data(), " ");
    while (token) {
      args.push_back(token);
      token = std::strtok(nullptr, " ");
    }
  } else if (lua_type(L, 1) == LUA_TTABLE) {
    int n = luaL_len(L, 1);
    if (n == 0) {
      lua_pushstring(L, "bad argument #1 to 'run' (length should > 0)");
      throw std::runtime_error(lua_tostring(L, -1));
    }

    for (int i = 1; i <= n; ++i) {
      if (lua_geti(L, 1, i) == LUA_TSTRING) {
        args.push_back(lua_tostring(L, -1));
      } else {
        lua_pushfstring(L, "bad element #%d in argument #1 to 'run' (string expected, got %s)", i, luaL_typename(L, -1));
        throw std::runtime_error(lua_tostring(L, -1));
      }
      lua_pop(L, 1);
    }
  } else {
    lua_pushfstring(L, "bad argument #1 to 'run' (table or string expected, got %s)", luaL_typename(L, 1));
    throw std::runtime_error(lua_tostring(L, -1));
  }

  if (lua_type(L, 2) != LUA_TTABLE) {
    lua_pushfstring(L, "bad argument #2 to 'run' (table expected, got %s)", luaL_typename(L, 2));
    throw std::runtime_error(lua_tostring(L, -1));
  }

  lua_getfield(L, 2, "shell");
  shell = lua_toboolean(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, 2, "check");
  check = lua_toboolean(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, 2, "capture_output");
  capture_output = lua_toboolean(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, 2, "file");
  if (lua_type(L, -1) == LUA_TSTRING) {
    file = lua_tostring(L, -1);
  } else if (lua_type(L, -1) != LUA_TNIL) {
    lua_pushfstring(L, "bad element 'file' in argument #2 to 'run' (string expected, got %s)", luaL_typename(L, -1));
    throw std::runtime_error(lua_tostring(L, -1));
  }
  lua_pop(L, 1);

  lua_getfield(L, 2, "cwd");
  if (lua_type(L, -1) == LUA_TSTRING) {
    cwd = lua_tostring(L, -1);
  } else if (lua_type(L, -1) != LUA_TNIL) {
    lua_pushfstring(L, "bad element 'cwd' in argument #2 to 'run' (string expected, got %s)", luaL_typename(L, -1));
    throw std::runtime_error(lua_tostring(L, -1));
  }
  lua_pop(L, 1);

  lua_getfield(L, 2, "env");
  if (lua_type(L, -1) == LUA_TTABLE) {
    int t = lua_gettop(L); /* table is in the stack at index 't' */
    lua_pushnil(L); /* first key */
    while (lua_next(L, t) != 0) {
      /* uses 'key' (at index -2) and 'value' (at index -1) */
      const char *key = lua_tostring(L, -2);
      if (lua_type(L, -1) == LUA_TTABLE) {
        lua_getglobal(L, "table");
        lua_getfield(L, -1, "concat");
        lua_pushvalue(L, -3);
        lua_pushstring(L, ":");
        lua_call(L, 2, 1);

        lua_pushfstring(L, "%s=%s", key, lua_tostring(L, -1));
        envs[key] = lua_tostring(L, -1);
        lua_pop(L, 3);
      } else {
        lua_pushfstring(L, "%s=%s", key, lua_tostring(L, -1));
        envs[key] = lua_tostring(L, -1);
        lua_pop(L, 1);
      }

      /* removes 'value'; keeps 'key' for next iteration */
      lua_pop(L, 1);
    }
  } else if ( !lua_isnil(L, -1) ) {
    lua_pushfstring(L, "bad element 'env' in argument #2 to 'run' (string expected, got %s)", luaL_typename(L, -1));
    throw std::runtime_error(lua_tostring(L, -1));
  }

  exe = args[0];
  if (exe.find('/') == std::string::npos) {
    exe = which(L, exe);
  }
}

int Process::exec(lua_State *L) {
  if (capture_output) {
    if (pipe2(stdout_pipefd, O_CLOEXEC) == -1) {
      lua_pushstring(L, strerror(errno));
      throw std::runtime_error(lua_tostring(L, -1));
    }
    if (pipe2(stderr_pipefd, O_CLOEXEC) == -1) {
      lua_pushstring(L, strerror(errno));
      throw std::runtime_error(lua_tostring(L, -1));
    }
  }

  child_pid = fork();
  if (child_pid < 0) {
    lua_pushfstring(L, "fork() failed: %s", strerror(errno));
    throw std::runtime_error(lua_tostring(L, -1));
  }
  if (child_pid == 0) {
    fork_child();
  }
  return fork_parent(L);
}

int Process::fork_parent(lua_State *L)
{
  lua_newtable(L);
  if (capture_output) {
    std::stringstream ss_stdout, ss_stderr;

    /* close unused pipe fds */
    close(stdout_pipefd[1]);
    close(stderr_pipefd[1]);

    do {
      int sz;
      char buf[1024];

      memset(buf, 0, sizeof(buf));
      sz = read(stdout_pipefd[0], buf, sizeof(buf));
      if (sz > 0) {
        ss_stdout.write(buf, sz);
      } else if (sz < 0) {
        lua_pushstring(L, strerror(errno));
        throw std::runtime_error(lua_tostring(L, -1));
      }

      memset(buf, 0, sizeof(buf));
      sz = read(stderr_pipefd[0], buf, sizeof(buf));
      if (sz > 0) {
        ss_stderr.write(buf, sz);
      } else if (sz < 0) {
        lua_pushstring(L, strerror(errno));
        throw std::runtime_error(lua_tostring(L, -1));
      }
    } while ( child_is_running(L) );

    close(stdout_pipefd[0]);
    close(stderr_pipefd[0]);

    const auto &stdout_str = ss_stdout.str();
    lua_pushlstring(L, stdout_str.data(), stdout_str.size());
    lua_setfield(L, -2, "stdout");

    const auto &stderr_str = ss_stderr.str();
    lua_pushlstring(L, stderr_str.data(), stderr_str.size());
    lua_setfield(L, -2, "stderr");
  }

  int status = wait_child(L);

  if (WIFEXITED(status)) {
    int exit_code = WEXITSTATUS(status);
    // printf("pid = %d, check = %d, exit(%d)\n", child_pid, check, exit_code);

    lua_pushinteger(L, exit_code);
    lua_setfield(L, -2, "exit_code");
    lua_pushstring(L, "exit");
    lua_setfield(L, -2, "exit_reason");

    if (check && exit_code != 0) {
      lua_pushfstring(L, "'run' exit with %d", exit_code);
      throw std::runtime_error(lua_tostring(L, -1));
    }
  }

  if (WIFSIGNALED(status)) {
    int signal_num = WTERMSIG(status);
    // printf("pid = %d, check = %d, signal %d\n", child_pid, check, signal_no);

    lua_pushinteger(L, signal_num);
    lua_setfield(L, -2, "signal");
    lua_pushstring(L, "signal");
    lua_setfield(L, -2, "exit_reason");

    if (check) {
      lua_pushfstring(L, "'run' exit with signal %d", signal_num);
      throw std::runtime_error(lua_tostring(L, -1));
    }
  }

  return 1;
}

void Process::fork_child(void)
{
  int i;
  std::vector<const char *> argv(args.size()+1, nullptr);
  std::vector<const char *> envp(envs.size()+1, nullptr);

  for (i = 0; i < args.size(); ++i) {
    argv[i] = args[i].data();
  }

  i = 0;
  for (auto &kv : envs) {
    envp[i++] = kv.second.data();
  }

  fs::current_path(cwd);

  if (capture_output) {
    /* 0 - r, 1 - w */
    close(stdout_pipefd[0]);
    close(stderr_pipefd[0]);
    if (dup2(stdout_pipefd[1], STDOUT_FILENO) == -1) {
      perror("dup2(pipefd, STDOUT_FILENO):");
      exit(EXIT_FAILURE);
    }
    if (dup2(stderr_pipefd[1], STDERR_FILENO) == -1) {
      perror("dup2(pipefd, STDERR_FILENO):");
      exit(EXIT_FAILURE);
    }
  } else {
    if (file.empty()) {
      int fd = open("/dev/null", O_WRONLY|O_CLOEXEC, 0666);
      if (dup2(fd, STDOUT_FILENO) == -1) {
        perror("dup2(fd, STDOUT_FILENO):");
        exit(EXIT_FAILURE);
      }
      if (dup2(fd, STDERR_FILENO) == -1) {
        perror("dup2(fd, STDERR_FILENO):");
        exit(EXIT_FAILURE);
      }
    } else {
      int fd = open(file.c_str(), O_WRONLY|O_CREAT|O_CLOEXEC, 0666);
      if (dup2(fd, STDOUT_FILENO) == -1) {
        perror("dup2(fd, STDOUT_FILENO):");
        exit(EXIT_FAILURE);
      }
      if (dup2(fd, STDERR_FILENO) == -1) {
        perror("dup2(fd, STDERR_FILENO):");
        exit(EXIT_FAILURE);
      }

      printf("PWD=%s\n", cwd.c_str());
      printf("%s\n", envs["PATH"].c_str());
      {
        for (i = 0; i < args.size(); ++i) {
          if (i == 0) {
            printf("%s \\\n", exe.c_str());
          } else {
            printf("  %s %c\n", argv[i], (i < args.size() - 1 ? '\\' : ' '));
          }
        }
      }
    }
  }

  if (execve(exe.data(), const_cast<char* const*>(argv.data()), const_cast<char* const*>(envp.data())) == -1) {
    perror("execve():");
    exit(0);
  }
}

bool Process::child_is_running(lua_State *L)
{
  if (WIFEXITED(waitpid_status) || WIFSIGNALED(waitpid_status)) {
    return false;
  }

  pid_t pid = waitpid(child_pid, &waitpid_status, WNOHANG);

  if (pid == -1) {
    lua_pushfstring(L, "check running failed: %s", strerror(errno));
    throw std::runtime_error(lua_tostring(L, -1));
  }

  if (pid == 0) {
    return true;    
  } else {
    return false;
  }
}

int  Process::wait_child(lua_State *L)
{
  int status = 0;
  pid_t ret;

  if (WIFEXITED(waitpid_status) || WIFSIGNALED(waitpid_status)) {
    return waitpid_status;
  }

  do {
    ret = ::waitpid(child_pid, &status, 0);
  } while (  (ret == -1 && errno == EINTR)
          || (ret != -1 && !WIFEXITED(status) && !WIFSIGNALED(status)) );

  if (ret == -1) {
    lua_pushstring(L, strerror(errno));
    throw std::runtime_error(lua_tostring(L, -1));
  }

  return status;
}

std::string Process::which(lua_State *L, const std::string &name)
{
  const char *delimitors = ":";
  std::string paths = envs["PATH"];
  char *token = std::strtok(paths.data(), delimitors);
  while (token) {
    auto full_path = fs::path(token) / name;
    if (fs::exists(full_path)) {
      return full_path;
    }
    token = std::strtok(nullptr, delimitors);
  }
  lua_pushfstring(L, "%s is not found.", name.c_str());
  throw std::runtime_error(lua_tostring(L, -1));
}
