#include "XbeeInterface.h"

int XbeeInit()
{
  XBEE_COM_PORT_INIT();
  XBEE_COM_PORT_SETBAUD(XBEE_BAUD_RATE);
  return 0;
}

int XbeeReceivePacket(DynamixelPacket * packet)
{
  int ret = -1;

  int c = XBEE_COM_PORT_GETCHAR();         //read one char (non-blocking)
  while( c != EOF)
  {
    ret = DynamixelPacketProcessChar(c,packet);
    if (ret > 0)
      break;
    c   = XBEE_COM_PORT_GETCHAR();
  }

  return ret;
}

int XbeeSendPacket(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size)
{
  if (size > 254)
    return -1;

  uint8_t size2 = size+2;
  uint8_t ii;
  uint8_t checksum=0;

  XBEE_COM_PORT_PUTCHAR(0xFF);   //two header bytes
  XBEE_COM_PORT_PUTCHAR(0xFF);
  XBEE_COM_PORT_PUTCHAR(id);
  XBEE_COM_PORT_PUTCHAR(size2);  //length
  XBEE_COM_PORT_PUTCHAR(type);
  
  checksum += id + size2 + type;
  
  //payload
  for (ii=0; ii<size; ii++)
  {
    XBEE_COM_PORT_PUTCHAR(*buf);
    checksum += *buf++;
  }
  
  XBEE_COM_PORT_PUTCHAR(~checksum);
  
  return 0;
}

int XbeeSendRawPacket(DynamixelPacket * packet)
{
  uint8_t * buf = packet->buffer;
  uint8_t size  = packet->lenExpected;

  uint8_t ii;
  
  for (ii=0; ii<size; ii++)
    XBEE_COM_PORT_PUTCHAR(*buf++);
    
  return 0;
}
