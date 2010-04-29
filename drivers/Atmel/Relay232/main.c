#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "uart1.h"


void init(void)
{


  uart0_init();
  uart0_setbaud(9600);

  uart1_init();
  uart1_setbaud(9600);

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

  while (1) {
    count++;

    c = uart0_getchar();
    if (c != EOF) {
      uart1_putchar(c);
    }

    c = uart1_getchar();
    if (c != EOF) {
      uart0_putchar(c);
    }
  }

  return 0;
}
