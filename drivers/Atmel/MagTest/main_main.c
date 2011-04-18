#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <avr/sleep.h>
#include <stdio.h>

#include "MagicMicroCom.h"
#include "uart0.h"
#include "GpsInterface.h"
#include "HostInterface.h"
#include "DebugInterface.h"
#include "adc.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

#define NUM_ADC_CHANNELS 16

#define DEBUG

void init(void)
{
  // Enable output for led
  //DDRB |= _BV(DDB7);
  
  //enable AD converter
  adc_init();

  //enable communication to PC over USB
  HostInit();
  
  //enable communications with gps
  GpsInit();
  
  
  //DebugInit();

  //enable global interrupts 
  sei (); 
}

int HostPacketHandler(DynamixelPacket * packet)
{
  return 0;
}

int ImuPacketHandler(uint16_t * vals, uint8_t len)
{
  HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_PACKET_TYPE_RAW,
                 (uint8_t*)vals,len*sizeof(uint16_t));
  return 0;
}

int GpsPacketHandler(uint8_t * buf, uint8_t len)
{

/*  
#ifdef DEBUG
  //output this to debug port
  uint8_t ii;
  for (ii=0; ii<len;ii++)
    DEBUG_COM_PORT_PUTCHAR(*buf++);
#endif
*/  
  HostSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_PACKET_TYPE_ASCII, buf,len);

  return 0;
}

int main(void)
{
  int16_t len;
  uint8_t * buf;
  
  DynamixelPacket hostPacketIn;
  DynamixelPacketInit(&hostPacketIn);
  
  uint16_t adcVals[NUM_ADC_CHANNELS] = {1,2,3,4,5,6,7,8};

  init();

/*  
#ifdef DEBUG
  //print out initialization message
  DEBUG_COM_PORT_PUTSTR(MMC_READY_MSG);
#endif
*/
  
  while(1)
  {
    //receive packet from host
    
    len=HostReceivePacket(&hostPacketIn);
    if (len>0)
      HostPacketHandler(&hostPacketIn);
    
  
    //receive a line from gps
    len=GpsReceiveLine(&buf);
    if (len>0)
      GpsPacketHandler(buf,len);
      //GpsPacketHandler(tempBuf,tempLen);
    
    cli();   //disable interrupts to prevent race conditions while copying
    len = adc_get_data(adcVals);
    sei();   //re-enable interrupts
    
    if (len > 0)
      ImuPacketHandler(adcVals,len);
    
  }

  return 0;
}
