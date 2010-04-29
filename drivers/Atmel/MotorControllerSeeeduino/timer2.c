#include "timer2.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer2_overflow_callback)(void);

ISR(TIMER2_OVF_vect)
{
  if (timer2_overflow_callback)
    timer2_overflow_callback();
}

void timer2_init(void)
{
  // 1/1024 prescaler = 0.0164 overflow period
  TCCR2B = _BV(CS20) | _BV(CS21) | _BV(CS22);
  
  //enable overflow interrupt
  TIMSK2 = _BV(TOIE2);
}

void timer2_set_overflow_callback(void (*callback)(void))
{
  timer2_overflow_callback = callback;
  if (timer2_overflow_callback)
    TIMSK2 |= _BV(TOIE2);
  else
    TIMSK2 &= ~(_BV(TOIE2));
}
