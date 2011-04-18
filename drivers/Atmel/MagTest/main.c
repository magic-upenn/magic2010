#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>

#include "config.h"
#include "HostInterface.h"
#include "MagHmc5843.h"



//--------------------------------------------------------------------
// Main Init function
//--------------------------------------------------------------------
void init(void)
{

   //enable communication to PC over USB
  HostInit();
    
  MagInit();

  //enable global interrupts 
  sei();
  
}



int main(void)
{
  
  init();

  uart0_printf("mag test initialized\r\n");

  int ret;
  uint16_t magData[4];

  while(1)
  {
    ret = MagGetData(magData);
    if (ret == 0)
    {
      uart0_printf("*** %d %d %d %d\r\n",magData[0],magData[1],magData[2],magData[3]);      
      _delay_ms(50);
    }

    _delay_ms(2);
    //uart0_putchar('.');
  }  
  

  return 0;
}
