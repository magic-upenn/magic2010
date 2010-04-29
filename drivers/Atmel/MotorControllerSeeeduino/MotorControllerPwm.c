#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include "MotorControllerPwm.h"

#define PWM_PERIOD 10000
#define PWM_INIT_WIDTH 1530

#define V_DDR DDRB
#define W_DDR DDRB
#define V_PIN PB1
#define W_PIN PB2
#define V_PULSE_WIDTH OCR1A
#define W_PULSE_WIDTH OCR1B


void MotorControllerPwmInit()
{
  //Clear OC1A and OC1B on compare match when up-counting
  //set on compare match when down-counting
  TCCR1A |= _BV(COM1A1) | _BV(COM1B1);
  
  //8x prescalar, enable pwm phase freq mode
  //gives 0.5 us per tick
  //pulse width is increased by 1us per tick (2*8/16000000)
  TCCR1B  = _BV(CS11) | _BV(WGM13);

  //enable OC1A and OC1B as outputs
  V_DDR |= _BV(V_PIN);
  V_DDR |= _BV(W_PIN);
  
  //set the pwm period (ticks)
  ICR1  = PWM_PERIOD;
  
  //set the initial pulse width (ticks)
  //the Sabertooth controller will calibrate to this value
  V_PULSE_WIDTH = PWM_INIT_WIDTH;
  W_PULSE_WIDTH = PWM_INIT_WIDTH; 
}

int MotorControllerPwmSetVel(int8_t v, int8_t w)
{
  V_PULSE_WIDTH = PWM_INIT_WIDTH + 4*(int16_t)v;
  W_PULSE_WIDTH = PWM_INIT_WIDTH + 4*(int16_t)w;
  return 0;
}
