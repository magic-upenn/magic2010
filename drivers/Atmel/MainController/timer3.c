#include "timer3.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer3_overflow_callback)(void);
void (*timer3_compa_callback)(void);

ISR(TIMER3_OVF_vect)
{
  if (timer3_overflow_callback)
    timer3_overflow_callback();
}

ISR(TIMER3_COMPA_vect)
{
  if (timer3_compa_callback)
    timer3_compa_callback();
}

void timer3_init(void)
{
  TCCR3B = _BV(CS32); // CS32: prescaler = 1/256, 1.0486 ms cycle, 16uS tic.
}

void timer3_set_overflow_callback(void (*callback)(void))
{
  timer3_overflow_callback = callback;
  if (timer3_overflow_callback)
    TIMSK3 |= _BV(TOIE3);
  else
    TIMSK3 &= ~(_BV(TOIE3));
}

void timer3_set_compa_callback(void (*callback)(void))
{
  timer3_compa_callback = callback;
  if (timer3_compa_callback)
    TIMSK3 |= _BV(OCIE3A);
  else
    TIMSK3 &= ~(_BV(OCIE3A));
}

