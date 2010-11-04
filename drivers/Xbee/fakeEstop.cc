#include "Xbee.hh"
#include <string>
#include "ErrorMessage.hh"
#include "DynamixelPacket.h"
#include "MagicMicroCom.h"
#include "Timer.hh"

using namespace std;
using namespace Upenn;


int main(int argc, char * argv[])
{
  string dev = string("/dev/ttyUSB0");
  int baud   = 115200;
  int ret;

  if (argc > 1)
    dev = string(argv[1]);

  Xbee xbee;
  if (xbee.Connect(dev,baud))
  {
    PRINT_ERROR("could not connect to device "<<dev<<"\n");
    return -1;
  }

  //const char * data = "Hello World!\r\n";
  const int bufSize = 256;
  uint8_t buf[bufSize];
  
  const int nRobots = 9;
  uint8_t mode[nRobots+1] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  
  //for (int ii=0; ii<nRobots+1; ii++)
  //  mode[ii] = 0;

  ret = DynamixelPacketWrapData(MMC_ESTOP_DEVICE_ID,
           MMC_ESTOP_STATE,mode,nRobots+1,buf,bufSize);
  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }
  
  while(1)
  {


    if (xbee.WritePacket(buf,ret,0xFFFF))
    {
      PRINT_ERROR("could not write packet\n");
      return -1;
    }
    

    //PRINT_INFO("wrote packet!\n");

    usleep(1000000);


    XbeeFrame frame;
    XbeeFrameInit(&frame);

    int xbeePacketLen, dynamixelPacketLen, payloadLen;
    
    
    DynamixelPacket dpacketIn;
  
    
    while(1)
    {
      xbeePacketLen      = xbee.ReceivePacket(&frame,0.1);
      if (xbeePacketLen < 1)
        break;
      
      dynamixelPacketLen = xbeePacketLen - XBEE_FRAME_RX_OVERHEAD;
      payloadLen         = dynamixelPacketLen - 6;
      uint8_t * dpayload = frame.buffer+XBEE_FRAME_OFFSET_PAYLOAD;
      uint8_t * payload  = dpayload + 5;
      
      uint8_t apiId = XbeeFrameGetApiId(&frame); 
      //printf("\ngot frame of size %d of type %x\n",xbeePacketLen,apiId);

      if (apiId == XBEE_API_RX_PACKET_16)
      {
        uint16_t src = (frame.buffer[4]<<8) + frame.buffer[5];
        int rssi = -frame.buffer[6];

        //printf("src = %x, rssi = %d\n",src,-rssi);
        /*
        printf("payload: ");
        for (int ii=0; ii<payloadLen; ii++)
          printf("%X ",payload[ii]);
        printf("\n");
        */
        memcpy(dpacketIn.buffer,dpayload,dynamixelPacketLen);
        int id = DynamixelPacketGetId(&dpacketIn);
        int type = DynamixelPacketGetType(&dpacketIn);
        
        if ( (id == MMC_ESTOP_DEVICE_ID) && (type == MMC_ESTOP_STATE) )
        {
          int robotId    = payload[0];
          int estopState = payload[1];
          printf("Robot%d: Estop = %d, RSSI=%d\n",robotId,estopState,rssi);
        }
        //printf("packet of id %d and type %d\n",id,type);
        
      }
    }

  }

  return 0;
}