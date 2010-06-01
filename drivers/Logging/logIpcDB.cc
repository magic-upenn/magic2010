#include "IpcLoggerDB.hh"
#include "ErrorMessage.hh"
#include <string>

using namespace Upenn;
using namespace std;


IpcLoggerDB * logger = NULL;

void ShutdownFn(int code)
{
  PRINT_INFO("exiting..\n");
  if (logger) delete logger;
  exit(0);
}


int main(int argc, char *argv[])
{
  string hostname = string("localhost");

  //check input arguments
  if (argc < 3)
  {
    PRINT_ERROR("\nplease provide two arguments: 1)xml file name, 2)log file name\n" <<
                "or three arguments: 1)xml file name, 2)log file name, 3) IPC hostname\n" );
    return -1;
  }

  if (argc == 4)
    hostname = string(argv[3]);

  //create an instance of the logger
  logger = new IpcLoggerDB();

  //connect to the ipc server
  if (logger->Connect(hostname))
  {
    PRINT_ERROR("could not connect to ipc\n");
    return -1;
  }

  //initialize (subscribe to messages, specified in the xml file)
  if (logger->Initialize(argv[1],argv[2]))
  {
    PRINT_ERROR("could not initialize logging");
    return -1;
  }

  int timeoutMs = 100;

  signal(SIGINT,ShutdownFn);

  while(1)
  {
    if (logger->Receive(timeoutMs))
    {
      PRINT_ERROR("could not receive messages\n");
      return -1;
    }
  }
}
