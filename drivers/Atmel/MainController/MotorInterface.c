#include "MotorInterface.h"
#include "rs485.h"


int MotorsInit()
{
  rs485_init();
  rs485_setbaud(MOTOR_INTERFACE_BAUD_RATE);
  
  return 0;
}

int MotorsReceiveEncoderData(uint8_t ** buf)
{

  return 0;
}

int MotorsSendControls(float v, float w)
{


  return 0;
}