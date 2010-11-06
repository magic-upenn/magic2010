#include "SerialDevice.hh"
#include <string>
#include "Timer.hh"
#include <iostream>
#include "MagicMicroCom.h"
#include "DynamixelPacket.h"
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <math.h>

using namespace std;

//#define SERIAL_BAUD_RATE 115200
//#define SERIAL_BAUD_RATE 230400
#define SERIAL_BAUD_RATE 1000000

SerialDevice sd;


int ProcessPacket(DynamixelPacket * packet)
{
  static int cntrrr=0;
  static int rotCntr=0;
  cntrrr++;

  int ii;
  uint8_t * bp;
  uint8_t size = DynamixelPacketGetSize(packet)-2;  //dont count the checksum
  uint16_t * p;
  float * fp;
  
  bp = DynamixelPacketGetData(packet);  //pointer to the data

  switch (DynamixelPacketGetId(packet))
  {
    case MMC_GPS_DEVICE_ID:
    
      printf("got gps packet: ");
      for (ii=0; ii<size; ii++)
      {
        printf("%c",*bp++);
      }
      printf("\n");
      break;
      
    case MMC_IMU_DEVICE_ID:
    
      if (DynamixelPacketGetType(packet) == MMC_IMU_RAW)
      {
        p = (uint16_t*)bp;
        size /= 2;

        printf("got raw imu packet: ");
        for (ii=0; ii<size; ii++)
        {
          printf("%d ",*p);
          p++;
        }
        printf("\n");

      }
      else if (DynamixelPacketGetType(packet) == MMC_IMU_ROT)
      {
        fp = (float*)bp;

        double rpy[6];
        rpy[0] = fp[0];
        rpy[1] = fp[1];
        rpy[2] = fp[2];
        rpy[3] = fp[3];
        rpy[4] = fp[4];
        rpy[5] = fp[5];

        printf("got rot imu packet: %f %f %f %f %f %f\n",
               rpy[0]*180/M_PI,rpy[1]*180/M_PI,rpy[2]*180/M_PI,
               rpy[3]*180/M_PI,rpy[4]*180/M_PI,rpy[5]*180/M_PI);


      }
      else if (DynamixelPacketGetType(packet) == MMC_MAG_RAW)
      {
        int16_t * magData = (int16_t*)DynamixelPacketGetData(packet);
        
        printf("got mag packet : ");
          
        for (int ii=1; ii<4; ii++)
          printf("%d ",magData[ii]);
        printf("\n");
        
      }
      
    default:
      break;
  }
  
  return 0;
}

int main(int argc, char * argv[])
{
  string dev = string("/dev/ttyUSB0");
  if (argc >=2)
    dev = string(argv[1]);
  
  //connect to microcontroller
  if (sd.Connect(dev.c_str(),SERIAL_BAUD_RATE))
  {
    printf("could not open device\n");
    return -1;
  }
  
  sd.FlushInputBuffer();
  
  unsigned char * inBuf = new unsigned char[128];
  int n;
  
  Upenn::Timer timer0;
  timer0.Tic();
  
  //read the startup message, since microcontroller resets
  //when pc connects
  
  DynamixelPacket packet;
  DynamixelPacketInit(&packet);
  int ret;

  

  while(1)
  {
    n = sd.ReadChars((char*)inBuf,1,1000);
    for (int ii=0; ii<n; ii++)
    {
      //printf("0x%x ",inBuf[ii],inBuf[ii]); fflush(stdout);
      ret = DynamixelPacketProcessChar(inBuf[ii],&packet);
      
      if (ret > 0)
      {
        ProcessPacket(&packet);
      }
    }
  }
    
  sd.Disconnect();

  return 0;
}

