#include "Xbee.hh"
#include <string>
#include "ErrorMessage.hh"
#include "DynamixelPacket.h"
#include "Timer.hh"

using namespace std;
using namespace Upenn;


int main()
{
  string dev = string("/dev/ttyUSB0");
  int baud   = 115200;
  int ret;


  Xbee xbee;
  if (xbee.Connect(dev,baud))
  {
    PRINT_ERROR("could not connect to device "<<dev<<"\n");
    return -1;
  }

  //const char * data = "Hello World!\r\n";
  const int bufSize = 256;
  uint8_t buf[bufSize];

  ret = DynamixelPacketWrapData(0,0,NULL,0,buf,bufSize);
  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }
  
  while(1)
  {
    if (xbee.WritePacket(buf,ret))
    {
      PRINT_ERROR("could not write packet\n");
      return -1;
    }
    

    PRINT_INFO("wrote packet!\n");

    XbeeFrame frame;
    XbeeFrameInit(&frame);

    int len;
  
    
    while(1)
    {
      len = xbee.ReceivePacket(&frame,1);
      uint8_t apiId = XbeeFrameGetApiId(&frame); 
      printf("\ngot frame of size %d of type %x\n",len,
                apiId);

      if (apiId == XBEE_API_RX_PACKET_16)
      {
        uint16_t src = (frame.buffer[4]<<8) + frame.buffer[5];
        int rssi = frame.buffer[6];

        printf("src = %x, rssi = %d\n",src,-rssi);
        break;
      }
    }
  }

  return 0;
}

