#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>
#include "uart.h"
#include "DynamixelPacket.h"

#define INSTRUCTION_PING           0x01
#define INSTRUCTION_READ_DATA      0x02
#define INSTRUCTION_WRITE_DATA     0x03
#define INSTRUCTION_REG_WRITE      0x04
#define INSTRUCTION_ACTION         0x05
#define INSTRUCTION_RESET          0x06
#define INSTRUCTION_SYNC_WRITE     0x83
#define LASER_POINTER_ID 32

void LaserOn()
{
  PORTC |= _BV(PINC0); 
}

void LaserOff()
{
  PORTC &= ~(_BV(PINC0)); 
}

int main(void)
{
  DynamixelPacket dpacketIn;
  DynamixelPacketInit(&dpacketIn);

  int c;
  int ret;
  uint8_t id;
  uint8_t type;
  uint8_t * data;
  
  uart_init();
  uart_setbaud(1000000);

  //enable global interrupts 
  sei ();

  //uart_printf("hello\n\r");

  DDRC  |= _BV(PINC0);
  LaserOff();
  

  while(1)
  {
    c= uart_getchar();
    if (c != EOF)
    {
      ret = DynamixelPacketProcessChar(c,&dpacketIn);
      if (ret > 0)
      {
        id = DynamixelPacketGetId(&dpacketIn);
        if (id == LASER_POINTER_ID)
        {
          type = DynamixelPacketGetType(&dpacketIn);
          if (type == INSTRUCTION_WRITE_DATA)
          {
            data = DynamixelPacketGetData(&dpacketIn);
            if (data[0] == 0)
              LaserOff();
            else
              LaserOn();
          }
        }
      }
    }
  }
  

  return 0;
}
