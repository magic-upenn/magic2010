#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "uart3.h"


void init(void)
{


  uart0_init();
  uart0_setbaud(115200);

  uart3_init();
  uart3_setbaud(115200);

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
      uart3_putchar(c);
    }

    c = uart3_getchar();
    if (c != EOF) {
      uart0_putchar(c);
    }
  }

  return 0;
}
