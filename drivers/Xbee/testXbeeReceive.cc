#include "Xbee.hh"
#include <string>
#include "ErrorMessage.hh"
#include <vector>
#include <stdint.h>

using namespace std;
using namespace Upenn;


int main()
{
  string dev = string("/dev/ttyUSB0");
  int baud   = 115200;


  Xbee xbee;
  if (xbee.Connect(dev,baud))
  {
    PRINT_ERROR("could not connect to device "<<dev<<"\n");
    return -1;
  }

  XbeeFrame frame;
  XbeeFrameInit(&frame);

  int len;
  
  while(1)
  {
    len = xbee.ReceivePacket(&frame,1);
    uint8_t apiId = XbeeFrameGetApiId(&frame); 
    printf("\ngot frame of size %d of type %x\n",len,apiId);

    if (apiId == XBEE_API_RX_PACKET_16)
    {
      uint16_t src = (frame.buffer[4]<<8) + frame.buffer[5];
      int rssi = frame.buffer[6];

      printf("src = %x, rssi = %d\n",src,-rssi);
    }
  }
  return 0;
}
