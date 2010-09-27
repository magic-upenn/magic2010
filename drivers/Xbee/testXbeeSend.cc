#include "Xbee.hh"
#include <string>
#include "ErrorMessage.hh"

using namespace std;
using namespace Upenn;


int main()
{
  string dev = string("/dev/ttyUSB1");
  int baud   = 115200;


  Xbee xbee;
  if (xbee.Connect(dev,baud))
  {
    PRINT_ERROR("could not connect to device "<<dev<<"\n");
    return -1;
  }

  //const char * data = "Hello World!\r\n";
  const char * data = "a";

  while(1)
  {
    if (xbee.WritePacket((uint8_t*)data,1))
    {
      PRINT_ERROR("could not write packet\n");
      return -1;
    }
  usleep(10000);
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
    }
  }

  return 0;
}

