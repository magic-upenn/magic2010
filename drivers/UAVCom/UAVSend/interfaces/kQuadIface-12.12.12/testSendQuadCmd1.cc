/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "kQuadInterface.hh"

int main()
{
  char * dev = (char*)"/dev/ttyUSB1";
  int baud   = 1000000;
  
  kQuadInterface kqi;
  
  if (kqi.Connect(dev,baud))
  {
    printf("could not connect to the device\n");
    return -1;
  }
  
  if (kqi.StartSendThread())
  {
    printf("could not start send thread\n");
    return -1;
  }
  
  if (kqi.StartRecvThread())
  {
    printf("could not start receive thread\n");
    return -1;
  }
  
  uint8_t quadId   = 1;
  uint8_t quadType = 0; //standard, 1 for nano
  uint8_t channel  = 1;
  
  float thrust = 1; //(grams) 1 for idle
  float roll   = 0; //radians
  float pitch  = 0; //radians
  float yaw    = 0; //radians
  
  list<ImuFiltData>     ifdata;
  list<ImuRawData>      irdata;
  list<BatteryData>     bdata;
  list<RcData>          rcdata;
  list<GpsNmeaData>     gpsndata;
  list<GpsUbloxData>   gpsudata;
  list<QuadStatusData>  qdata;
  list<ServoData>       sdata;
  
  while(1)
  {
    kqi.SendQuadCmd1(quadId, quadType, channel, thrust, roll, pitch, yaw);
    
    usleep(20000);
    
    if (kqi.GetImuFiltData(ifdata) > 0)
      printf("got imu data!\n");
    
    if (kqi.GetImuRawData(irdata) > 0)
      printf("got raw imu data!\n");
    
    //printf("."); fflush(stdout);
  }
  
 
  return 0;
}
