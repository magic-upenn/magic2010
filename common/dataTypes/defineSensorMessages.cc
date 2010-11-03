#include "MagicSensorDataTypes.hh"
#include "ipc.h"
#include <stdio.h>
#include <string>

using namespace std;
using namespace Magic;

int main(int argc, char * argv[])
{
  char * host = (char*)"localhost";
  char * id   = (char*)"1";
  
  if (argc > 1) host = argv[1];
  if (argc > 2) id   = argv[2];
  
  
  const int tempSize = 128;
  char temp[tempSize];
  
  
  IPC_connectModule("DefineSensorMessages",host);
  
  
  const char * names[]= { "GPS",
                          "Encoders",
                          "EstopState",
                          "ImuFiltered",
                          "Lidar0",
                          "Lidar1",
                          "Servo1",
                          "BatteryStatus",
                          "MotorStatus"};
  const int sizeNames = sizeof(names)/sizeof(*names);
  
  
  const char * formats[] = { GpsASCII::getIPCFormat(),
                             EncoderCounts::getIPCFormat(),
                             EstopState::getIPCFormat(),
                             ImuFiltered::getIPCFormat(),
                             LidarScan::getIPCFormat(),
                             LidarScan::getIPCFormat(),
                             ServoState::getIPCFormat(),
                             BatteryStatus::getIPCFormat(),
                             MotorStatus::getIPCFormat()
                          };
  
  const int sizeFormats = sizeof(formats)/sizeof(*formats);
  
  if (sizeNames != sizeFormats)
  {
    printf("size of the names array does not match the size of format array\n");
    return -1;
  }
  
  printf("defining messages...\n"); 
  for (int ii=0; ii<sizeNames; ii++)
  {
    string s = string("Robot%s/%s");
    snprintf(temp,tempSize,s.c_str(),id,names[ii]);
    printf("  %s ...\n",temp);
    IPC_defineMsg(temp,IPC_VARIABLE_LENGTH,formats[ii]);
  }

  printf("done\n");
  return 0;
}
