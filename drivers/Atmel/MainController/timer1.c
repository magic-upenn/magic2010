#include "timer1.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer1_overflow_callback)(void);
void (*timer1_compa_callback)(void);

ISR(TIMER1_OVF_vect)
{
  if (timer1_overflow_callback)
    timer1_overflow_callback();
}

ISR(TIMER1_COMPA_vect)
{
  if (timer1_compa_callback)
    timer1_compa_callback();
}

void timer1_init(void)
{
  
  TCCR1B = _BV(CS10) | _BV(CS11); // CS10 | CS11: prescaler = 1/64, 262.1 ms cycle

  /*
  TCCR1B = _BV(CS10);
  
  TCCR1B = _BV(WGM13) ; // prescaler = 8, 32.8 ms cycle
  TIMSK1 = _BV(OCIE1A);
  
  DDRB |= _BV(DDB5);
  OCR1A = 3000;
  ICR1  = 1000;
  */
  
  //TCCR1B = _BV(CS11); // CS11: prescaler = 8, 32.8 ms cycle
  //TIMSK1 = _BV(OCIE1A);
  //OCR1A = 12500;      //50 ms
  OCR1A = 1250;      //50 ms
}

void timer1_set_overflow_callback(void (*callback)(void))
{
  timer1_overflow_callback = callback;
  if (timer1_overflow_callback)
    TIMSK1 |= _BV(TOIE1);
  else
    TIMSK1 &= ~(_BV(TOIE1));
}

void timer1_set_compa_callback(void (*callback)(void))
{
  timer1_compa_callback = callback;
  if (timer1_compa_callback)
    TIMSK1 |= _BV(OCIE1A);
  else
    TIMSK1 &= ~(_BV(OCIE1A));
}
