#include "ErrorMessage.hh"
#include "MicroGateway.hh"
#include "Timer.hh"
#include "DynamixelPacket.h"
#include "MagicMicroCom.h"

using namespace std;
using namespace Upenn;


int main(int argc, char * argv[])
{
  char * sDev = (char*)"/dev/ttyUSB0";
  char * ipcHost = NULL;

  //get input arguments
  if (argc > 1)
  {
    sDev = argv[1];
  }
  
  
  if (argc > 2)
    ipcHost = argv[2];

  //connect to the serial bus
  MicroGateway * mg = new MicroGateway();
  if (mg->ConnectSerial(sDev,1000000))
  {
    PRINT_ERROR("could not connect to the serial bus\n");
    return -1;
  }

  if (mg->ConnectIPC())
  {
    PRINT_ERROR("could not connect to ipc\n");
    return -1;
  }
  
  while(1)
  {
    mg->Main();
  }
  
  return 0;
}

