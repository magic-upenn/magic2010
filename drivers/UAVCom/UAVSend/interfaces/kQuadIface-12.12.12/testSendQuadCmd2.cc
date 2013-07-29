/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "kQuadInterface.hh"

int main()
{
  char * dev = (char*)"/dev/ttyUSB0";
  int baud   = 1000000;
  
  kQuadInterface kqi;
  
  if (kqi.Connect(dev,baud))
  {
    printf("could not connect to the device\n");
    return -1;
  }
  
  if (kqi.StartSendThread())
  {
    printf("could not start thread\n");
    return -1;
  }
  
  uint8_t quadId   = 1;
  uint8_t quadType = 0; //standard
  uint8_t channel  = 1;
  
  uint16_t rpm0 = 3000;
  uint16_t rpm1 = 3000;
  uint16_t rpm2 = 3000;
  uint16_t rpm3 = 3000;
  
  while(1)
  {
    kqi.SendQuadCmd2(quadId, quadType, channel, rpm0, rpm1, rpm2, rpm3);
    
    usleep(50000);
    
    printf("."); fflush(stdout);
  }
  
 
  return 0;
}
