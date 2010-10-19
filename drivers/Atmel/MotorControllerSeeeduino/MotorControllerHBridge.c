#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include "MagicMicroCom.h"
#include "MotorControllerHBridge.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

#define RIGHT_FORWARD_DDR DDRE
#define RIGHT_REVERSE_DDR DDRH
#define LEFT_FORWARD_DDR  DDRH
#define LEFT_REVERSE_DDR  DDRH

#define RIGHT_FORWARD_PIN PE3
#define RIGHT_REVERSE_PIN PH3
#define LEFT_FORWARD_PIN  PH4
#define LEFT_REVERSE_PIN  PH5

#define RIGHT_FORWARD_PORT PORTE
#define RIGHT_REVERSE_PORT PORTH
#define LEFT_FORWARD_PORT  PORTH
#define LEFT_REVERSE_PORT  PORTH

#define RIGHT_FORWARD_PULSE_WIDTH OCR3A
#define RIGHT_REVERSE_PULSE_WIDTH OCR4A
#define LEFT_FORWARD_PULSE_WIDTH  OCR4B
#define LEFT_REVERSE_PULSE_WIDTH  OCR4C

#define RIGHT_FORWARD_REGISTER TCCR3A
#define RIGHT_REVERSE_REGISTER TCCR4A
#define LEFT_FORWARD_REGISTER  TCCR4A
#define LEFT_REVERSE_REGISTER  TCCR4A


#define __EnableRightForwardInt sbi(RIGHT_FORWARD_REGISTER,COM3A1)
#define __EnableRightReverseInt sbi(RIGHT_REVERSE_REGISTER,COM4A1)
#define __EnableLeftForwardInt sbi(LEFT_FORWARD_REGISTER,COM4B1)
#define __EnableLeftReverseInt sbi(LEFT_REVERSE_REGISTER,COM4C1)


#define __DisableRightForwardInt cbi(RIGHT_FORWARD_REGISTER,COM3A1)
#define __DisableRightReverseInt cbi(RIGHT_REVERSE_REGISTER,COM4A1)
#define __DisableLeftForwardInt cbi(LEFT_FORWARD_REGISTER,COM4B1)
#define __DisableLeftReverseInt cbi(LEFT_REVERSE_REGISTER,COM4C1)



void __ClearPwmPins()
{
  cbi(LEFT_FORWARD_PORT,LEFT_FORWARD_PIN);
  cbi(LEFT_REVERSE_PORT,LEFT_REVERSE_PIN);
  cbi(RIGHT_FORWARD_PORT,RIGHT_FORWARD_PIN);
  cbi(RIGHT_REVERSE_PORT,RIGHT_REVERSE_PIN);
}

void __EnableLeftForward()
{
  //disable interrupt for left reverse
  __DisableLeftReverseInt;
  
  //enable interrupt for left forward
  __EnableLeftForwardInt;  
}

void __EnableLeftReverse()
{
  //disable interrupt for left forward
  __DisableLeftForwardInt;
  
  //enable interrupt for left reverse
  __EnableLeftReverseInt;  
}

void __EnableRightForward()
{
  //disable interrupt for right reverse
  __DisableRightReverseInt;
  
  //enable interrupt for right forward
  __EnableRightForwardInt;  
}

void __EnableRightReverse()
{
  //disable interrupt for right forward
  __DisableRightForwardInt;
  
  //enable interrupt for right reverse
  __EnableRightReverseInt;  
}

void MotorControllerHBridgeInit()
{
  /* 
    -------------------------------------------------------
    Output PWM set up.
    Use 8bit Timer0 and 16bit Timer1 as 8bit timers
    to produce 4 pwm channels (two per each motor)
    Each channel controls the gate of the upper mosfet
    in the corresponding side of the h-bridge
    -------------------------------------------------------
  */
  
  LEFT_FORWARD_PULSE_WIDTH  = 0;
  LEFT_REVERSE_PULSE_WIDTH  = 0;
  RIGHT_FORWARD_PULSE_WIDTH = 0;
  RIGHT_REVERSE_PULSE_WIDTH = 0;
  
  //Clear OC0A, OC0B on compare match when up-counting, 
  //set on compare match when down-counting
  //__EnableLeftForwardInt;
  //__EnableLeftReverseInt;  //disabled at startup
  
  //Clear OC1A, OC1B on compare match when up-counting, 
  //set on compare match when down-counting
  //__EnableRightForwardInt;
  //__EnableRightReverseInt;  //disabled at startup
  
  //1/64 prescaler, PWM, phase correct mode with TOP=ICR3 and ICR4
  //period = 2*0.2621s
  TCCR3B = _BV(CS30) | _BV(CS31) | _BV(WGM33);
  TCCR4B = _BV(CS40) | _BV(CS41) | _BV(WGM43);

  //switching to 1/8 prescaler!!
  //TCCR3B = _BV(CS31) | _BV(WGM33);
  //TCCR4B = _BV(CS41) | _BV(WGM43);
  
  //set ICR3 and ICR4 to 0xFF to effectively make an 8 bit counter
  //now period is 2*0.001024s
  //--- disabled : after switch to 1/8 prescaler, this is now around 4Khz
  ICR3   = 0xFF;
  ICR4   = 0xFF;
  
  //enable outputs for 4 pwm channels
  sbi(LEFT_FORWARD_DDR,  LEFT_FORWARD_PIN);
  sbi(LEFT_REVERSE_DDR,  LEFT_REVERSE_PIN);
  sbi(RIGHT_FORWARD_DDR, RIGHT_FORWARD_PIN);
  sbi(RIGHT_REVERSE_DDR, RIGHT_REVERSE_PIN);
}


int MotorControllerHBridgeSetVel(int8_t v, int8_t w)
{
  //TODO: calculate leftVel and rightVel appropriately
  int16_t vtemp = (int16_t)v;
  int16_t leftVel  = vtemp - w;
  int16_t rightVel = vtemp + w;
  
  
 
  if (leftVel >= 0)
  {
    if (leftVel > 127)
      leftVel = 127;
  
    LEFT_FORWARD_PULSE_WIDTH  = (uint8_t)(leftVel*2);
    LEFT_REVERSE_PULSE_WIDTH  = 0;
    __EnableLeftForward();
  }
  else
  {
    if (leftVel < -127)
     leftVel = -127;
    LEFT_FORWARD_PULSE_WIDTH  = 0;
    LEFT_REVERSE_PULSE_WIDTH  = (uint8_t)((-leftVel)*2);
    __EnableLeftReverse();
  }
    
  if (rightVel >= 0)
  {
    if (rightVel > 127)
      rightVel = 127;
  
    RIGHT_FORWARD_PULSE_WIDTH  = (uint8_t)(rightVel*2);
    RIGHT_REVERSE_PULSE_WIDTH  = 0;
    __EnableRightForward();
  }
  else
  {
    if (rightVel < -127)
      rightVel = -127;
    RIGHT_FORWARD_PULSE_WIDTH  = 0;
    RIGHT_REVERSE_PULSE_WIDTH  = (uint8_t)((-rightVel)*2);
    __EnableRightReverse();
  }
  
  return 0;
}
