#include "MagicMicroCom.h"
#include "SerialDevice.hh"
#include "ErrorMessage.hh"
#include "DynamixelPacket.h"
#include <stdint.h>
#include "Timer.hh"
#include "../Atmel/MainController/ParamTable.h"
#include "MicroParams.hh"

using namespace Upenn;

SerialDevice sd;
const int bufSize = 256;
uint8_t buf[bufSize];

DynamixelPacket dpacket;

int ReadPacket(DynamixelPacket * dpacket, double timeout)
{
  char c;
  int size;
  Timer t0; t0.Tic();
  DynamixelPacketInit(dpacket);

  bool gotPacket = false;
  while (!gotPacket && (t0.Toc() < timeout))
  {
    int nchars = sd.ReadChars(&c,1);
    if (nchars==1)
    {
      int size = DynamixelPacketProcessChar(c,dpacket);
      if (size > 0)
        gotPacket = true;
    }
  }

  if (gotPacket)
    return size;
  else
    return -1;
}


int SwitchModeConfig()
{
  uint8_t mode = MMC_MC_MODE_CONFIG;

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_MODE_SWITCH,&mode,1,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd.WriteChars((char*)buf,ret);
  
  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool switchedMode = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd.ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * data = DynamixelPacketGetData(&dpacket);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_MODE_SWITCH)
          continue;

        gotResp = true;  

        if (*data == mode)
          switchedMode = true;
      }
    }
  }

  if (switchedMode)
    return 0;
  else
    return -1;
}

int WriteConfig(uint16_t offset, uint8_t * data, uint16_t size)
{
  uint8_t temp[256];
  memcpy(temp,&offset,2);
  memcpy(temp+2,&size,2);
  memcpy(temp+4,data,size);

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_EEPROM_WRITE,temp,size+4,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd.WriteChars((char*)buf,ret);


  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool wroteConfig = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd.ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * pdata = DynamixelPacketGetData(&dpacket);

        printf("got packet with id %d and type %d\n",id,type);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_EEPROM_WRITE)
          continue;

        gotResp = true;  

        uint16_t offset2;
        uint16_t size2;

        memcpy(&offset2,pdata,2);
        memcpy(&size2,pdata+2,2);

        if ((offset2 == offset) && (size2 == size))
          wroteConfig = true;
      }
    }
  }

  if (wroteConfig)
    return 0;
  else
    return -1;
}

int ReadConfig(uint16_t offset, uint8_t * data, uint16_t size)
{
  uint8_t temp[256];
  memcpy(temp,&offset,2);
  memcpy(temp+2,&size,2);

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_EEPROM_READ,temp,4,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd.WriteChars((char*)buf,ret);

  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool readConfig = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd.ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * pdata = DynamixelPacketGetData(&dpacket);

        printf("got packet with id %d and type %d\n",id,type);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_EEPROM_READ)
          continue;

        gotResp = true;  

        uint16_t offset2;
        uint16_t size2;

        memcpy(&offset2,pdata,2);
        memcpy(&size2,pdata+2,2);

        if ((offset2 == offset) && (size2 == size))
          readConfig = true;

        memcpy(data,pdata+4,size);
      }
    }
  }

  if (readConfig)
    return size;
  else
    return -1;
}


int main(int argc, char * argv[])
{
  char * dev = (char*)"/dev/ttyUSB0";
  int baud   = 1000000;
  int id     = 0;

  if (argc > 1)
    id = atoi(argv[1]);

  printf("setting param table for id %d\n",id);

  
  if (sd.Connect(dev,baud))
  {
    PRINT_ERROR("could not connect\n");
    return -1;
  }

  if (SwitchModeConfig() == 0)
  {
    PRINT_INFO("config mode set\n");
  }
  else
  {
    PRINT_ERROR("could not switch into config mode\n");
  }


  MicroParamsInitialize();
  ParamTable ptable;

  switch(id)
  {
    case 0:
      printf("please provide the robot id!!!\n");
      exit(1);

    case 1:
      ptable = ptable1;
      break;
    case 2:
      ptable = ptable2;
      break;
    case 3:
      ptable = ptable3;
      break;
    case 4:
      ptable = ptable4;
      break;
    case 5:
      ptable = ptable5;
      break;
    case 6:
      ptable = ptable6;
      break;
    case 7:
      ptable = ptable7;
      break;
    case 8:
      ptable = ptable8;
      break;
    case 9:
      ptable = ptable9;
      break;
    case 10:
      ptable = ptable10;
      break;
  
    default:
      printf("please provide the robot id!!!\n");
      exit(1);
  }
  

  printf("sizeof param table = %d\n",sizeof(ParamTable));

  if (WriteConfig(0,(uint8_t*)&ptable,sizeof(ParamTable)))
  {
    PRINT_ERROR("could not write config\n");
    return -1;
  }
  PRINT_INFO("set configuration\n");


  uint8_t id2;

  if (ReadConfig(0,&id2,1)!=1)
  {
    PRINT_ERROR("could not read config\n");
    return -1;
  }

  printf("read id = %d\n",id2);

  return 0;
}

