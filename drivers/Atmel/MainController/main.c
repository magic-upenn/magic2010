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
volatile uint8_t TWI_transBuff[10];
volatile uint8_t TWI_recBuff[10];
uint16_t adcCntr = 0;
uint16_t magCntr = 0;
uint16_t imuPacket[NUM_ADC_CHANNELS+1];
uint16_t magPacket[4];


volatile int8_t rcVelCmd[4] = {0,0,0,0};

uint8_t  rcPacketIn[16];
uint16_t rcValsIn[7];
volatile uint8_t rclen =0;
volatile int8_t nRCOvf =0;
volatile uint8_t rcInitialized = 0;

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

void RCTimingReset(void)
{
  rclen = 0;
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
  
  uart3_init();
  uart3_setbaud(115200);
  
  timer1_init();
  timer1_set_compa_callback(RCTimingReset);
  //timer1_set_overflow_callback(RCTimout);


  //timer for sending out estop status
  timer3_init();
  timer3_set_overflow_callback(SendEstopStatus);
  
  timer4_init();
  
  timer4_set_compa_callback(Rs485ResponseTimeout);

  //enable global interrupts 
  sei (); 
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

  LED_PC_ACT_PORT ^= _BV(LED_PC_ACT_PIN);

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
  LED_GPS_PORT ^= _BV(LED_GPS_PIN);
  HostSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_ASCII, buf,len);

  return 0;
}


int ProcessIncomingRCPacket()
{
  int16_t v = (((int16_t)rcValsIn[RC_V_IND]) - RC_V_BIAS)/2;
  int16_t w = (((int16_t)rcValsIn[RC_W_IND]) - RC_W_BIAS)/2;
  
  v = v < 128 ? v : 127;
  v = v > -127 ? v : -127;
  w = w < 128 ? w : 127;
  w = w > -127 ? w : -127;
  
  //send the RC packet to the host so that it can know the current RC channel values
  //DO NOT send it without host requesting it
  //TODO: implement response to host request for current RC command
  //HostSendPacket(MMC_RC_DEVICE_ID,MMC_RC_DECODED,(uint8_t*)rcValsIn,7*sizeof(uint16_t));
  
  
  
  rcVelCmd[0]=(int8_t)v;
  rcVelCmd[1]=(int8_t)w;
  
  //set the flag so that the command can be sent to the motor controller whenever
  //the RS485 bus frees up
  rcCmdPending = 1;

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
  
/*  
  uint8_t TWI_targetSlaveAddress, TWI_operation;
	TWI_Master_Initialise();
	TWI_targetSlaveAddress = 0x1E;		// MHCMC6352's address
	TWI_transBuff[0] = (TWI_targetSlaveAddress<<TWI_ADR_BITS) | (FALSE<<TWI_READ_BIT);
	TWI_transBuff[1] = 0x00;
  TWI_transBuff[2] = 0x18;
  TWI_transBuff[3] = 0x00;
  TWI_transBuff[4] = 0x00; 
	sei();								// enable interrupts
	TWI_Start_Transceiver_With_Data(TWI_transBuff,5);
	TWI_operation = SEND_DATA; 		// Set the next operation
*/  
  init();
  
  while(1)
  {
    //check the state of the estop input
    if (ESTOP_PORT & _BV(ESTOP_PIN))
    {
      estop = 1;
      LED_ESTOP_PORT |= _BV(LED_ESTOP_PIN);
    }
    else
    {
      estop = 0;
      LED_ESTOP_PORT &= ~(_BV(LED_ESTOP_PIN));
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
    
    
    //receive RC commands
    c = uart3_getchar();
    
    if (c != EOF)
    {
      TCNT1 = 0;
      rcPacketIn[rclen] = c;
    
      switch (rclen)
      {
        case 0:
        case 1:
          rclen++;
          break;
          
        
        default:
          rclen++;
          if (rclen & 0x01)  //process the first byte
          {
            rcChannel = (c & 0b00111100)>>2;        //extract the channel
            if (rcChannel < 0 || rcChannel> 6)
            {
              rclen = 0;
              break;
            }
            
            rcValsIn[rcChannel] = ((uint16_t)(c & 0x03))<<8;  //extract MSB part of the value
          }
          else             //process the second byte
          {
            rcValsIn[rcChannel] += c;                             //get the LSB
          }
          break;
      }
      
      if (rclen == 16)
      {
        ProcessIncomingRCPacket();
        rclen = 0;
        rcInitialized = 1;
        LED_RC_PORT ^= _BV(LED_RC_PIN);
      }
    }
    
    if (rcCmdPending && !rs485Blocked)
    {
      BusSendPacket(MMC_RC_DEVICE_ID,MMC_RC_DECODED,(uint8_t*)rcValsIn,7*sizeof(uint16_t));
    
    /*
      BusSendPacket(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                  MMC_MOTOR_CONTROLLER_VELOCITY_SETTING,
                  (uint8_t*)rcVelCmd, 4);
    */
    
      //reset the timer
      rcCmdPending = 0;
    }
    
    
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

        imuPacket[0] = adcCntr++;
        memcpy(&(imuPacket[1]),adcVals,NUM_ADC_CHANNELS*sizeof(uint16_t));
        HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_RAW,
                       (uint8_t*)imuPacket,(NUM_ADC_CHANNELS+1)*sizeof(uint16_t));
      }
    }
      
      
    //start magnetometer stuff  
      
/*     
    // Check if the TWI Transceiver has completed an operation.
		if ( ! TWI_Transceiver_Busy() )                              
		{
		    // Check if the last operation was successful
			if ( TWI_statusReg.lastTransOK )
			{
				// Determine what action to take now
				if (TWI_operation == SEND_DATA)
				{ 
					TWI_operation = REQUEST_DATA; 						// Set next operation
				}
				else if (TWI_operation == REQUEST_DATA)
				{ 
					// Request data from slave
					TWI_recBuff[0] = (TWI_targetSlaveAddress<<TWI_ADR_BITS) | (TRUE<<TWI_READ_BIT);
					TWI_Start_Transceiver_With_Data(TWI_recBuff,8); // 3 = TWI_recBuff[0] byte + heading high byte + heading low byte
					TWI_operation = READ_DATA_FROM_BUFFER; 			// Set next operation        
				}
				else if (TWI_operation == READ_DATA_FROM_BUFFER)
				{ 
					// Get the received data from the transceiver buffer
					TWI_Get_Data_From_Transceiver(TWI_recBuff);
          
          magPacket[0] = magCntr;
          magPacket[1] = (uint16_t)TWI_recBuff[1] << 8 | TWI_recBuff[2];
          magPacket[2] = (uint16_t)TWI_recBuff[3] << 8 | TWI_recBuff[4];
          magPacket[3] = (uint16_t)TWI_recBuff[5] << 8 | TWI_recBuff[6];
          HostSendPacket(MMC_IMU_DEVICE_ID,MMC_MAG_RAW,
                        (uint8_t*)magPacket,(4)*sizeof(uint16_t));
          magCntr++;
          
          TWI_operation = WAIT_FOR_REQUEST;
				}
        else if (TWI_operation == WAIT_FOR_REQUEST)
        {
          if (len > 0)
            compassReqCntr++;
            
          if (compassReqCntr == 1)
          {
            TWI_operation = REQUEST_DATA;    					// Set next operation
            compassReqCntr = 0;
          }
        }
        
			}
			else // Got an error during the last transmission
			{
				// Use TWI status information to detemine cause of failure and take appropriate actions. 
				//TWI_Act_On_Failure_In_Last_Transmission(TWI_Get_State_Info( ));
			}
		} //end of TWI status check
  
  //end magnetometer stuff
  */
  }

  

  return 0;
}
