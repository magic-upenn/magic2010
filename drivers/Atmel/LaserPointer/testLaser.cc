#include "SerialDevice.hh"
#include <iostream>
#include "DynamixelPacket.h"
#include <stdint.h>

int main(int argc, char * argv[])
{
  char * dev  = (char*)"/dev/ttyUSB0";
  char * baud = (char*)"1000000";
  uint8_t val = 1;

  if (argc>1)
    dev = argv[1];

  if (argc>2)
    baud=argv[2];

  if (argc>3)
    val = atoi(argv[3]);

  SerialDevice sd;
  if (sd.Connect(dev,baud))
  {
    printf("could not connect\n");
    return -1;
  }

  uint8_t id   = 32;
  uint8_t type = 0x03;


  const int nbuf = 128;
  uint8_t buf[nbuf];

  int len;
  len = DynamixelPacketWrapData(id,type,&val,1,buf,nbuf);

  if (len <0)
  {
    printf("could not wrap data\n");
    return -1;
  }

  if (sd.WriteChars((char*)buf,len) != len)
  {
    printf("could not write chars\n");
    return -1;
  }

  printf("sent cmd\n");
  sd.Disconnect();

  return 0;
}

