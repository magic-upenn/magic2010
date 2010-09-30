#include "Xbee.hh"
#include "XbeeFrame.h"
#include "ErrorMessage.hh"
#include "Timer.hh"

using namespace std;
using namespace Upenn;

Xbee::Xbee()
{
  this->connected = false;
}

Xbee::~Xbee()
{
  this->sd.Disconnect();
}

int Xbee::Connect(string dev, int baud)
{
  if (this->connected)
    return 0;

  int ret = this->sd.Connect(dev.c_str(),baud);

  if (ret ==0)
    this->connected = true;

  return ret;
}

int Xbee::Disconnect()
{
  this->sd.Disconnect();
  this->connected = false;
  return 0;
}

int Xbee::WritePacket(uint8_t * data, int size, int addr)
{
  if (!this->connected)
  {
    PRINT_ERROR("not connected\n");
    return -1;
  }

  if (size > XBEE_MAX_DATA_LENGTH)
  {
    PRINT_ERROR("data length is too big\n");
    return -1;
  }

  if (addr < 0 || addr > 0xFFFF)
  {
    PRINT_ERROR("address value is outside of range : "<<addr<<"\n");
    return -1;
  }

  int packetSize = size+XBEE_API_PACKET_OVERHEAD_BYTES;

  printf("packet size = %d\n",packetSize);

  vector<uint8_t> buf(packetSize);
  uint8_t * pbuf8 = &(buf[0]);
  uint8_t * pbuf8_2 = pbuf8;
  uint16_t * pbuf16;

  *pbuf8++  = XBEE_API_START_DELIMETER;        //start of packet
  pbuf16    = (uint16_t*)pbuf8; pbuf8+=2;        
  *pbuf16   = htons(size + 5);                 //size
  *pbuf8++  = XBEE_API_TX_REQUEST_16;          //type (tx request)
  *pbuf8++  = 0x00;                            //frame id
  pbuf16    = (uint16_t*)pbuf8; pbuf8+=2;
  *pbuf16   = htons(addr);                          //destination address
  *pbuf8++  = 0x00;                            //option

  memcpy(pbuf8,data,size);                     //payload
  pbuf8+=size;

  uint8_t sum = 0;
  pbuf8_2 += 3;  

  for (int ii=3; ii <packetSize-1; ii++)
    sum += *pbuf8_2++;
  sum = 0xFF - sum;

  *pbuf8 = sum;
  
  printf("sending chars: ");
  for (int ii=0; ii<packetSize; ii++)
    printf("%X ",buf[ii]);
  printf("\n");

  this->sd.WriteChars((char*)&(buf[0]),packetSize);

  return 0;
}

int Xbee::ReceivePacket(XbeeFrame * frame, double timeout)
{
  char c;
  int nchars;
  int ret;

  Timer t0; t0.Tic();

  while(1)
  {
    nchars = this->sd.ReadChars(&c,1);
    if (nchars>0)
    {
      t0.Toc(true); t0.Tic();
      printf("%X ",(uint8_t)c); fflush(stdout);
      ret = XbeeFrameProcessChar(c,frame);
      if (ret > 0)
      {
        //printf("got frame!!\n");
        return frame->lenExpected;
      }
    }
  }


  return 0;
}



