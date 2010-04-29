#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "rs485.h"


void init(void)
{


  uart0_init();
  uart0_setbaud(1000000);

  rs485_init();
  rs485_setbaud(1000000);

  sei();
}

int main(void)
{
  int c;
  unsigned long count = 0;

  init();
  //uart0_putstr("\r\nStarting Arduino Mega Relay program\r\n");

  //start the imu
  //uart1_putchar('9');

  while (1) 
  {
    count++;

    cli();
    c = uart0_getchar();
    if (c != EOF) {
      rs485_putchar(c);
    }

    c = rs485_getchar();
    if (c != EOF) {
      uart0_putchar(c);
    }
    sei();
  }

  return 0;
}
