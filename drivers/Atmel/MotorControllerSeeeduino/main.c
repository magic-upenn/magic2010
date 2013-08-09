/* Motor controller driver for Atmega 328
   
   Designed for a robot platform with 4 wheels, 4 motors and 
   two h-bridges, each driving two motors. Also counts 4
   dual encoder channels for position feedback
   
   Alex Kushleyev, Upenn, akushley@seas.upenn.edu
*/


#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>
#include "MagicMicroCom.h"
#include "DynamixelPacket.h"
#include "HostInterface.h"
#include "timer1.h"
#include "timer2.h"
#include "adc.h"

#define USE_H_BRIDGE
#ifdef USE_H_BRIDGE
  #include "MotorControllerHBridge.h"
  #define MOTOR_CONTROLLER_INIT MotorControllerHBridgeInit
  #define MOTOR_CONTROLLER_SET_VEL MotorControllerHBridgeSetVel
#else
  #include "MotorControllerPwm.h"
  #define MOTOR_CONTROLLER_INIT MotorControllerPwmInit
  #define MOTOR_CONTROLLER_SET_VEL MotorControllerPwmSetVel
#endif

#include "config.h"

typedef struct
{
  uint8_t id;
} ParamTable;

ParamTable EEMEM ptableE;
ParamTable ptableR;
uint8_t eepromTempData[sizeof(ParamTable)+4];


//store the encoder counts
volatile int16_t encCounts[4] = {0, 0, 0, 0};
volatile int8_t v=0, w=0;
volatile uint16_t n2OVF = 0;
volatile int8_t runMode = MODE_MANUAL;
volatile float vCl = 0, wCl = 0;


//imu data will come in over the rs485 bus
volatile float roll   = 0;
volatile float pitch  = 0;
volatile float yaw    = 0;
volatile float wroll  = 0;
volatile float wpitch = 0;
volatile float wyaw   = 0;


uint8_t  rcPacketIn[16];
uint16_t rcValsIn[7];
volatile uint8_t rclen =0;
volatile int8_t nRCOvf =0;
volatile uint8_t rcInitialized = 0;

volatile uint8_t myId = 0;
volatile uint8_t configMode = MMC_MC_MODE_RUN;

void ResetEncoderCounts()
{
  encCounts[0] = 0;
  encCounts[1] = 0;
  encCounts[2] = 0;
  encCounts[3] = 0;
}


void RCTimingReset(void)
{
  rclen = 0;
}

//reset the counter and overflow count to prevent timeout
void ResetMotorCmdTimeout()
{
  TCNT2 = 0;
  n2OVF = 0;
}

//safety timer overflow
void t2_overflow(void)
{
  n2OVF++;

  if (n2OVF == 12)     //6 = ~100 ms timeout 
  {
    v=0;
    w=0;
    MOTOR_CONTROLLER_SET_VEL(v,w);
    ResetMotorCmdTimeout();
  }
}

ISR(ENCODER0_INT_vec)
{
  //this inteerrupt will trigger on rising edge only
  //check the value of the second encoder channel
  switch( ENCODER0_VALUE_PORT & _BV(ENCODER0_VALUE_PIN) )
  {
    case 0:
      encCounts[0]++;
      break;
    default:
      encCounts[0]--;
      break;
  }
}

ISR(ENCODER1_INT_vec)
{
  //this inteerrupt will trigger on rising edge only
  //check the value of the second encoder channel
  switch( ENCODER1_VALUE_PORT & _BV(ENCODER1_VALUE_PIN) )
  {
    case 0:
      encCounts[1]++;
      break;
    default:
      encCounts[1]--;
      break;
  }
}

ISR(ENCODER2_INT_vec)
{
  //check the value of the second encoder channel
  switch( ENCODER2_VALUE_PORT & _BV(ENCODER2_VALUE_PIN) )
  {
    case 0:
      encCounts[2]++;
      break;
    default:
      encCounts[2]--;
      break;
  }
}

ISR(ENCODER3_INT_vec)
{
  //check the value of the second encoder channel
  switch( ENCODER3_VALUE_PORT & _BV(ENCODER3_VALUE_PIN) )
  {
    case 0:
      encCounts[3]++;
      break;
    default:
      encCounts[3]--;
      break;
  }
}

void init(void)
{
  /*
    ---------------------------------------------------------
    Encoder input set up
    There are total of 4 channels (2 per motor)
    Will set up 4 interrupts for each encoder CHA (channel A)
    Once interrupt triggers, check the value of CHB
    Increment/decrement counter depending on state of CHB
    Use indepedent interrupts INT0, INT1, INT4, INT5
    INTx interrupts are set up to trigger on rising edge
    PCINTx interrupts will trigger on either edge, so must 
    check the state of the trigger channel before counting
    --------------------------------------------------------
  */
  
  
  //set up interrupts INT0 and INT1 to trigger on rising edge
  EICRA |= _BV(ISC00) | _BV(ISC01) | _BV(ISC10) | _BV(ISC11);
  
  //set up interrupts INT4 and INT5 to trigger on rising edge
  EICRB |= _BV(ISC40) | _BV(ISC41) | _BV(ISC50) | _BV(ISC51);
  
  //enable interrupts INT0 and INT1
  EIMSK |= _BV(INT0) | _BV(INT1) | _BV(INT4) | _BV(INT5) ;
  
  //initialize the timer
  timer2_init();
  
  //enable the overflow interrupt for command timeout
  timer2_set_overflow_callback(t2_overflow);
  
  //initialize the motor controller stuff
  MOTOR_CONTROLLER_INIT(); 
  
  //initialize the communications ports
  //HostInit();
  uart0_init();
  uart0_setbaud(HOST_BAUD_RATE);
  
  rs485_init();
  rs485_setbaud(BUS_BAUD_RATE);
  
  
  uart3_init();
  uart3_setbaud(RC_BAUD_RATE);
  
  timer1_init();
  timer1_set_compa_callback(RCTimingReset);
  
  STATUS_LED_DDR |= _BV(STATUS_LED_PIN);
  ACT_LED_DDR |= _BV(ACT_LED_PIN);
  
  
  STATUS_LED_PORT |= _BV(STATUS_LED_PIN);
  ACT_LED_PORT |= _BV(ACT_LED_PIN);


  //enable AD converter
  adc_init();

  sei();
  
  // uart0_printf("hello!\r\n");
}


int WriteParamTableBlock(uint16_t offset, uint8_t * data, uint16_t size)
{
  eeprom_write_block(data,((uint8_t*)&(ptableE))+offset,size);
  //eeprom_write_block((uint8_t*)0,data,1);
  //eeprom_write_byte((uint8_t*)offset,*data);
  return size;
}

int ReadParamTableBlock(uint16_t offset, uint8_t * data, uint16_t size)
{
  eeprom_read_block(data,((uint8_t*)&(ptableE))+offset,size);
  //eeprom_read_block(data,0,1);
  //*data = eeprom_read_byte((uint8_t*)offset);
  return size;
}

int SendRS485Packet(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size)
{
  if (size > 254)
    return -1;

  uint8_t size2 = size+2;
  uint8_t ii;
  uint8_t checksum=0;

  checksum += id + size2 + type;

  rs485_putchar(0xFF);   //two header bytes
  rs485_putchar(0xFF);
  rs485_putchar(id);
  rs485_putchar(size2);  //length
  rs485_putchar(type);
  
  //payload
  for (ii=0; ii<size; ii++)
  {
    rs485_putchar(*buf);
    checksum += *buf++;
  }
  
  rs485_putchar(~checksum);
  
  return 0;
}


int SetVelocity(int8_t vNew, int8_t wNew)
{  
  if (vNew<MIN_V && vNew>-MIN_V)
    vNew = 0;
    
  if (wNew<MIN_W && wNew>-MIN_W)
    wNew = 0;
  
  //IIR filter
  v = vNew*0.3 + v*0.7;
  w = wNew*0.3 + w*0.7;
  //v=vtemp;
  //w=wtemp;
  
    
  //set the velocities
  MOTOR_CONTROLLER_SET_VEL(v,w);
  
  ResetMotorCmdTimeout();

  return 0;
}

int ProcessIncomingRCPacket()
{
  uint16_t targetIdVal = rcValsIn[RC_SELECT_IND];
  uint8_t targetId;
  
  if (targetIdVal < 300)
    targetId = 1;
  else if (targetIdVal < 600)
    targetId = 2;
  else
    targetId = 3;
    
  if (targetId != myId)
    return 0;


  uint16_t newMode = rcValsIn[RC_MODE_IND];
  if (newMode > RC_MODE_THRESH)
    runMode = MODE_AUTONOMOUS;
  else
  {
      //    runMode=MODE_AUTONOMOUS;
          // commented for new controller
          ///*
    runMode = MODE_MANUAL;
    int16_t vtemp = (((int16_t)rcValsIn[RC_V_IND]) - RC_V_BIAS)/2;
    int16_t wtemp = (((int16_t)rcValsIn[RC_W_IND]) - RC_W_BIAS)/2;
    
    vtemp = vtemp <  128 ? vtemp :  127;
    vtemp = vtemp > -127 ? vtemp : -127;
    wtemp = wtemp <  128 ? wtemp :  127;
    wtemp = wtemp > -127 ? wtemp : -127;
  
  
    SetVelocity((int8_t)vtemp,(int8_t)wtemp);
    //*/
  }
  
  //uart0_printf("%d %d %d %d %d %d %d \r\n",rcValsIn[0],rcValsIn[1],rcValsIn[2],
  //          rcValsIn[3],rcValsIn[4],rcValsIn[5],rcValsIn[6]);
            
  return 0;
}


int main(void)
{
  int16_t c, ret,len;
  int8_t rcChannel=0;
  unsigned long count = 0;
  uint16_t counts[9];    //packet counter and 4 encoder counts + 2 current measurements + 2 temp
  uint16_t adcVals[NUM_ADC_CHANNELS];

  counts[0] = 0;
  uint8_t * dataPr;
  uint8_t packetId;
  float * imuData;
  float * tempf;
  
  DynamixelPacket dpacket;
  DynamixelPacket hostPacketIn;
  DynamixelPacketInit(&dpacket);
  DynamixelPacketInit(&hostPacketIn);

  init();

  //hack to initialize the h-bridges properly
  SetVelocity(5,0);
  _delay_ms(100);
  SetVelocity(-5,0);
  _delay_ms(100);
  SetVelocity(0,0);
  
  
  //read the id
  ReadParamTableBlock(0, &myId, sizeof(uint8_t));

  while (1) 
  {
    count++;

    cli();
    len = adc_get_data(adcVals);
    sei();

    if (len > 0)
      memcpy(&(counts[5]),adcVals,4*sizeof(uint16_t));
      
    c = uart0_getchar();
    if (c != EOF && c == 'i')
    {
      while(1)
      {
        c = uart0_getchar();
        if (c != EOF)
        {
          myId = c - '0';
          if (myId > 0 && myId < 4)
          {
            WriteParamTableBlock(0, &myId, sizeof(uint8_t));
            uart0_printf("changed id to %d\r\n",myId);
          }
          else
            uart0_printf("invalid id : %d\r\n",myId);

          break;
        }
      }
    }
    
    while ((c = rs485_getchar()) != EOF)
    {
      //uart0_putchar(c);
      ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret < 1)
        continue;
        
      packetId = DynamixelPacketGetId(&dpacket);
        
      if (packetId == MMC_MOTOR_CONTROLLER_DEVICE_ID)
      {
        TOGGLE_ACT_LED;
          
        switch (DynamixelPacketGetType(&dpacket))
        {
          case MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST:
          
            cli();
            memcpy(&(counts[1]),encCounts,4*sizeof(uint16_t));
            ResetEncoderCounts();
            sei();
            
            counts[1] = -counts[1];
            counts[3] = -counts[3];
          
            //return back the counter
            counts[0] = *(uint16_t*)DynamixelPacketGetData(&dpacket);
          
            SendRS485Packet(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                            MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE,
                            (uint8_t*)counts,9*sizeof(uint16_t));

            break;
          case MMC_MOTOR_CONTROLLER_VELOCITY_SETTING:
            dataPr = DynamixelPacketGetData(&dpacket);
            
            if (runMode == MODE_AUTONOMOUS)
              SetVelocity((int8_t)dataPr[0],(int8_t)dataPr[1]);

  /*
            //send back the confirmation with the counter
            SendRS485Packet(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                            MMC_MOTOR_CONTROLLER_VELOCITY_CONFIRMATION,
                            dataPr,sizeof(uint16_t));
  */
            break;

          case MMC_MOTOR_CONTROLLER_VELOCITY_SETTING_CLOSED_LOOP:
            tempf = (float*)DynamixelPacketGetData(&dpacket);
            if (runMode == MODE_AUTONOMOUS)
            {
              vCl = *tempf++;
              wCl = *tempf;
            }
            break;

          case MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST_AND_IMU_DATA:
            cli();
            memcpy(&(counts[1]),encCounts,4*sizeof(uint16_t));
            ResetEncoderCounts();
            sei();
            
            counts[1] = -counts[1];
            counts[3] = -counts[3];

            dataPr = DynamixelPacketGetData(&dpacket);
          
            //return back the counter
            counts[0] = *(uint16_t*)(dataPr);
          
            SendRS485Packet(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                            MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE,
                            (uint8_t*)counts,5*sizeof(uint16_t));


            //store the imu data
            imuData = (float*)(dataPr+2); //first two bytes are the uint16 counter
            roll   = *imuData++;
            pitch  = *imuData++;
            yaw    = *imuData++;
            wroll  = *imuData++;
            wpitch = *imuData++;
            wyaw   = *imuData;
            break;
            
          default:
            break;
        }
      }
      else if (packetId == MMC_RC_DEVICE_ID)
      {
        TOGGLE_ACT_LED;
          
        switch (DynamixelPacketGetType(&dpacket))
        {
          case MMC_RC_DECODED:
            //overwrite the rc vals
            memcpy(rcValsIn,DynamixelPacketGetData(&dpacket),7*sizeof(uint16_t));
            
            //process the new packet
            ProcessIncomingRCPacket();
            break;
            
          default:
            break;
      
        }
      }
    }
    
    
    
    //handle RC input
    while ((c = uart3_getchar()) != EOF)
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
        TOGGLE_ACT_LED;
      }
    }
    
  }
  
  return 0;
}

