#ifndef IPC_HELPER_HH
#define IPC_HELPER_HH

#define MAX_IPC_HELPER_HOSTNAME_LENGTH 128
#define MAX_IPC_HELPER_PID_LENGTH 128

#include <string>
#include <unistd.h>

using namespace std;

namespace Upenn
{
  class IpcHelper
  {
  public: static string GetProcessName(string type = string(""));
  };
}

#endif //IPC_HELPER_HH
