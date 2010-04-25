#include "IpcHelper.hh"
#include <cstdio>

using namespace std;
using namespace Upenn;

string IpcHelper::GetProcessName(string type)
{
  string processName;
  char hostname[MAX_IPC_HELPER_HOSTNAME_LENGTH];
  int gotHostName = gethostname(hostname,MAX_IPC_HELPER_HOSTNAME_LENGTH);
  char pid[MAX_IPC_HELPER_PID_LENGTH];
  
  snprintf(pid,MAX_IPC_HELPER_PID_LENGTH,"%d",(int)getpid());
  
  if (gotHostName == 0)
    processName = string("(") + string(hostname) + string(")-" + type + "-") + string(pid);
  else
    processName = string("(") + string("unknownHost") + string(")-" + type + "-") + string(pid);

  return processName;
}
