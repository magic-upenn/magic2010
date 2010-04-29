#include "timer4.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer4_overflow_callback)(void);
void (*timer4_compa_callback)(void);

uint16_t timer4_period_tics = 1250; //1250 = 5ms with 1/64 prescaler

ISR(TIMER4_OVF_vect)
{
  if (timer4_overflow_callback)
    timer4_overflow_callback();
}

ISR(TIMER4_COMPA_vect)
{
  if (timer4_compa_callback)
    timer4_compa_callback();
}

void timer4_reset()
{
  TCNT4=0;
}

void timer4_set_back_tics(uint16_t delayTics)
{
  if (delayTics > timer4_period_tics)
    TCNT4 = 0;
  else
    TCNT4 = timer4_period_tics - delayTics;
}

void timer4_init(void)
{
  TCCR4B = _BV(CS40) | _BV(CS41); // prescaler = 1/64, 4us per tic, 262ms cycle
  
  OCR4A = timer4_period_tics;   

}

void timer4_set_overflow_callback(void (*callback)(void))
{
  timer4_overflow_callback = callback;
  if (timer4_overflow_callback)
    TIMSK4 |= _BV(TOIE4);
  else
    TIMSK4 &= ~(_BV(TOIE4));
}

void timer4_set_compa_callback(void (*callback)(void))
{
  timer4_compa_callback = callback;
  if (timer4_compa_callback)
    TIMSK4 |= _BV(OCIE4A);
  else
    TIMSK4 &= ~(_BV(OCIE4A));
}

void timer4_enable_overflow_callback()
{
  TIMSK4 |= _BV(TOIE4);
}

void timer4_disable_overflow_callback()
{
  TIMSK4 &= ~(_BV(TOIE4));
}

void timer4_enable_compa_callback()
{
  TCNT4=0;
  TIMSK4 |= _BV(OCIE4A);
}

void timer4_disable_compa_callback()
{
  TIMSK4 &= ~(_BV(OCIE4A));
}
