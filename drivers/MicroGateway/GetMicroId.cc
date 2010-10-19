#include "MagicMicroCom.h"
#include "SerialDevice.hh"
#include "ErrorMessage.hh"
#include "DynamixelPacket.h"
#include <stdint.h>
#include "Timer.hh"
#include "../Atmel/MainController/ParamTable.h"
#include "MicroGateway2.hh"

using namespace Upenn;

MicroGateway mg;
DynamixelPacket dpacket;

int main()
{
  char * dev = (char*)"/dev/ttyUSB0";
  int baud   = 1000000;
  uint8_t id;

  if (mg.ConnectSerial(dev,baud))
  {
    PRINT_ERROR("could not connect\n");
    return -1;
  }

  if (mg.SwitchModeConfig() == 0)
  {
    PRINT_INFO("config mode set\n");
  }
  else
  {
    PRINT_ERROR("could not switch into config mode\n");
  }

  if (mg.ReadConfig(0,&id,1)!=1)
  {
    PRINT_ERROR("could not read config\n");
    return -1;
  }

  printf("read id = %d\n",id);

  return 0;
}

