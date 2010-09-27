#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>

#include "config.h"
#include "MagicMicroCom.h"
#include "GpsInterface.h"
#include "HostInterface.h"
#include "BusInterface.h"
#include "adc.h"
#include "TWI_Master.h"
#include "uart3.h"
#include "timer1.h"
#include "timer3.h"
#include "timer4.h"
#include "attitudeFilter.h"

DynamixelPacket hostPacketIn;
DynamixelPacket busPacketIn;

uint16_t adcVals[NUM_ADC_CHANNELS];
float rpy[3];
float wrpy[3];
float imuOutVals[7];

uint16_t adcCntr = 0;
uint16_t imuPacket[NUM_ADC_CHANNELS+1];

volatile uint8_t rs485Blocked = 0;
volatile uint8_t rcCmdPending = 0;

uint8_t estop = 0;

inline void PutUInt16(uint16_t val)
{
  uint8_t * p = (uint8_t*)&val;
  HOST_COM_PORT_PUTCHAR(*(p+1));
  HOST_COM_PORT_PUTCHAR(*p);
}

void SendEstopStatus(void)
{
  HostSendPacket(MMC_ESTOP_DEVICE_ID,MMC_ESTOP_STATE,
                 (uint8_t*)&estop,1);
}


int XbeeSendPacket(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size)
{
  if (size > 254)
    return -1;

  uint8_t size2 = size+2;
  uint8_t ii;
  uint8_t checksum=0;

  XBEE_COM_PORT_PUTCHAR(0xFF);   //two header bytes
  XBEE_COM_PORT_PUTCHAR(0xFF);
  XBEE_COM_PORT_PUTCHAR(id);
  XBEE_COM_PORT_PUTCHAR(size2);  //length
  XBEE_COM_PORT_PUTCHAR(type);
  
  checksum += id + size2 + type;
  
  //payload
  for (ii=0; ii<size; ii++)
  {
    XBEE_COM_PORT_PUTCHAR(*buf);
    checksum += *buf++;
  }
  
  XBEE_COM_PORT_PUTCHAR(~checksum);
  
  return 0;
}


void Rs485ResponseTimeout(void)
{
  rs485Blocked = 0;
  
  //disable the timeout, since we consider the packet lost
  timer4_disable_compa_callback();
}

void InitLeds()
{
  LED_ERROR_DDR     |= _BV(LED_ERROR_PIN);
  LED_PC_ACT_DDR    |= _BV(LED_PC_ACT_PIN);
  LED_ESTOP_DDR     |= _BV(LED_ESTOP_PIN);
  LED_GPS_DDR       |= _BV(LED_GPS_PIN);
  LED_RC_DDR        |= _BV(LED_RC_PIN);
  
}

void init(void)
{

  LED_ERROR_ON;

  //enable AD converter
  adc_init();

  ResetImu();

  //enable communication to PC over USB
  HostInit();
  
  //enable communication to the bus
  BusInit();
  
  //enable communications with gps
  GpsInit();
  
  InitLeds();
  
  XBEE_COM_PORT_INIT();
  XBEE_COM_PORT_SETBAUD(XBEE_BAUD_RATE);

  //timer for sending out estop status
  timer3_init();
  timer3_set_overflow_callback(SendEstopStatus);
  
  timer4_init();
  
  timer4_set_compa_callback(Rs485ResponseTimeout);

  //enable global interrupts 
  sei();

  LED_ERROR_OFF;
}

int ImuPacketHandler(uint8_t len)
{
  imuPacket[0] = adcCntr++;
  memcpy(&(imuPacket[1]),adcVals,NUM_ADC_CHANNELS*sizeof(uint16_t));
  HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_RAW,
                 (uint8_t*)imuPacket,(NUM_ADC_CHANNELS+1)*sizeof(uint16_t));
  return 0;
}


int HostPacketHandler(DynamixelPacket * dpacket)
{
  //TODO: not all messages should be forwarded onto the bus
  uint8_t forward=1;
  uint8_t id = DynamixelPacketGetId(dpacket);
  uint8_t type = DynamixelPacketGetType(dpacket);

  if (id == MMC_IMU_DEVICE_ID)
  {
    forward =0;
    switch(type)
    {
      case MMC_IMU_RESET:
        ResetImu();
        break;

    }
  }

  if ((estop == 1) && (id == MMC_MOTOR_CONTROLLER_DEVICE_ID) && 
  (type == MMC_MOTOR_CONTROLLER_VELOCITY_SETTING) )
    forward = 0;

  LED_PC_ACT_TOGGLE;

  if (forward)
  {
    BusSendRawPacket(dpacket);
    rs485Blocked = 1;
  }
  
  //enable the timeout for RS485 bus
  //timer4_enable_compa_callback();
   
  return 0;
}

int BusPacketHandler(DynamixelPacket * packet)
{
  timer4_disable_compa_callback();
  rs485Blocked = 0;
  HostSendRawPacket(packet);
  
  //disable the timeout for RS485 bus, since the response came back
  
  return 0;
}

int GpsPacketHandler(uint8_t * buf, uint8_t len)
{
  LED_GPS_TOGGLE;
  HostSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_ASCII, buf,len);
  //XbeeSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_ASCII, buf,len);
  XBEE_COM_PORT_PRINTF("got gps on robot 2 %d\r\n",TCNT3);

  return 0;
}


int main(void)
{
  int16_t len;
  uint8_t * buf;
  int c;
  
  int8_t rcChannel=0;
  
  uint8_t compassReqCntr = 0;
  
  DynamixelPacketInit(&hostPacketIn);
  DynamixelPacketInit(&busPacketIn);
  

  init();
  
  while(1)
  {
    //check the state of the estop input
    if (ESTOP_PORT & _BV(ESTOP_PIN))
    {
      estop = 1;
      LED_ESTOP_ON;
    }
    else
    {
      estop = 0;
      LED_ESTOP_OFF;
    }

    //receive packet from host
    len=HostReceivePacket(&hostPacketIn);
    if (len>0)
      HostPacketHandler(&hostPacketIn);
    
    //receive packet from RS485 bus
    len=BusReceivePacket(&busPacketIn);
    if (len>0)
      BusPacketHandler(&busPacketIn);
      
      
    //receive a line from gps
    len=GpsReceiveLine(&buf);
    if (len>0)
      GpsPacketHandler(buf,len);

    
    cli();   //disable interrupts to prevent race conditions while copying
    len = adc_get_data(adcVals);
    sei();   //re-enable interrupts
    
    if (len > 0)
    {
      if (ProcessImuReadings(adcVals,rpy,wrpy) == 0) //will return 0 if updated, 1 if not yet updated
      {
        //send stuff out
        memcpy(imuOutVals,  &rpy[0], sizeof(float));
        memcpy(imuOutVals+1,&rpy[1], sizeof(float));
        memcpy(imuOutVals+2,&rpy[2], sizeof(float));
        memcpy(imuOutVals+3,&wrpy[0],sizeof(float));
        memcpy(imuOutVals+4,&wrpy[1],sizeof(float));
        memcpy(imuOutVals+5,&wrpy[2],sizeof(float));
    
        HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_ROT, 
                  (uint8_t*)imuOutVals,6*sizeof(float));
      }

      imuPacket[0] = adcCntr++;
      memcpy(&(imuPacket[1]),adcVals,NUM_ADC_CHANNELS*sizeof(uint16_t));
      HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_RAW,
		     (uint8_t*)imuPacket,(NUM_ADC_CHANNELS+1)*sizeof(uint16_t));
    }
  }

  

  return 0;
}
