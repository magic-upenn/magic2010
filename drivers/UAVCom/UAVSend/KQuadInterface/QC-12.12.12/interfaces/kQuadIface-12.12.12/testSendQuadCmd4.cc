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
  
  float thrust = 1; //(grams)1 for idle
  float roll   = 0; //radians
  float pitch  = 0; //radians
  float yaw    = 0; //radians
  
  float droll  = 0;
  float dpitch = 0;
  float dyaw   = 0;
  
  float kp_roll   = 550;
  float kp_pitch  = 550;
  float kp_yaw    = 800;
  
  float kd_roll   = 42;
  float kd_pitch  = 42;
  float kd_yaw    = 50;
  
  float mx        = 0;  //extra moments (in grams)
  float my        = 0;
  float mz        = 0;
  
  while(1)
  {
    kqi.SendQuadCmd4(quadId, quadType, channel, thrust, roll, pitch, yaw,
                     droll,dpitch,dyaw, kp_roll,kp_pitch,kp_yaw, kd_roll,kd_pitch,kd_yaw,mx,my,mz);
    
    usleep(50000);
    
    printf("."); fflush(stdout);
  }
  
 
  return 0;
}