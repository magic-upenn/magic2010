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
  uint8_t buf[12];
  buf[0] = 0x55;
  buf[1] = 0x55;
  buf[10] = 0xAA;
  buf[11] = 0xAA;
  while(1)
  {
    ret = MagGetData(magData);
    if (ret == 0)
    {
      buf[2] = magData[0] >> 8;
      buf[3] = magData[0] & 0xFF;
      buf[4] = magData[1] >> 8;
      buf[5] = magData[1] & 0xFF;
      buf[6] = magData[2] >> 8;
      buf[7] = magData[2] & 0xFF;
      buf[8] = magData[3] >> 8;
      buf[9] = magData[3] & 0xFF;
      uart0_putdata(buf, 12); // takes ~ 1ms (115200bps)
      _delay_ms(19);
    }
  }  

  return 0;
}
