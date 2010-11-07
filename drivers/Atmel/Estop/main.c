#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>
#include <string.h>
#include "uart0.h"
#include "DynamixelPacket.h"
#include "uart1.h"
#include "MagicMicroCom.h"



#define LED_OUT10_PIN PC0
#define LED_OUT9_PIN  PC1
#define LED_OUT8_PIN  PC2
#define LED_OUT7_PIN  PC3
#define LED_OUT6_PIN  PC4
#define LED_OUT5_PIN  PC5
#define LED_OUT4_PIN  PC6
#define LED_OUT3_PIN  PC7
#define LED_OUT2_PIN  PA7
#define LED_OUT1_PIN  PA6
#define LED_OUT0_PIN  PA5

#define LED_OUT10_PORT PORTC
#define LED_OUT9_PORT  PORTC
#define LED_OUT8_PORT  PORTC
#define LED_OUT7_PORT  PORTC
#define LED_OUT6_PORT  PORTC
#define LED_OUT5_PORT  PORTC
#define LED_OUT4_PORT  PORTC
#define LED_OUT3_PORT  PORTC
#define LED_OUT2_PORT  PORTA
#define LED_OUT1_PORT  PORTA
#define LED_OUT0_PORT  PORTA


#define LED_OUT10_DDR DDRC
#define LED_OUT9_DDR  DDRC
#define LED_OUT8_DDR  DDRC
#define LED_OUT7_DDR  DDRC
#define LED_OUT6_DDR  DDRC
#define LED_OUT5_DDR  DDRC
#define LED_OUT4_DDR  DDRC
#define LED_OUT3_DDR  DDRC
#define LED_OUT2_DDR  DDRA
#define LED_OUT1_DDR  DDRA
#define LED_OUT0_DDR  DDRA


#define RP_IN10_PIN PB0
#define RP_IN9_PIN  PB1
#define RP_IN8_PIN  PB2
#define RP_IN7_PIN  PB3
#define RP_IN6_PIN  PL0
#define RP_IN5_PIN  PL1
#define RP_IN4_PIN  PL2
#define RP_IN3_PIN  PL3
#define RP_IN2_PIN  PL4
#define RP_IN1_PIN  PL5
#define RP_IN0_PIN  PL6

#define RP_IN10_PORT PINB
#define RP_IN9_PORT  PINB
#define RP_IN8_PORT  PINB
#define RP_IN7_PORT  PINB
#define RP_IN6_PORT  PINL
#define RP_IN5_PORT  PINL
#define RP_IN4_PORT  PINL
#define RP_IN3_PORT  PINL
#define RP_IN2_PORT  PINL
#define RP_IN1_PORT  PINL
#define RP_IN0_PORT  PINL

#define D_IN10_PIN PE2
#define D_IN9_PIN  PE6
#define D_IN8_PIN  PE7
#define D_IN7_PIN  PG3
#define D_IN6_PIN  PG4
#define D_IN5_PIN  PD6
#define D_IN4_PIN  PD5
#define D_IN3_PIN  PD4
#define D_IN2_PIN  PJ7
#define D_IN1_PIN  PJ6


#define D_IN10_PORT PINE
#define D_IN9_PORT  PINE
#define D_IN8_PORT  PINE
#define D_IN7_PORT  PING
#define D_IN6_PORT  PING
#define D_IN5_PORT  PIND
#define D_IN4_PORT  PIND
#define D_IN3_PORT  PIND
#define D_IN2_PORT  PINJ
#define D_IN1_PORT  PINJ

#define READ_VAL(   port , pin )  port &  _BV(pin)     
#define SET_PIN(    port , pin )  port |= _BV(pin)     
#define CLEAR_PIN(  port , pin )  port &= ~(_BV(pin))  
#define SET_INPUT(  port , pin )  port &= ~(_BV(pin))  
#define SET_OUTPUT( port , pin )  port |= _BV(pin)


uint8_t volatile commandedState[11]   = {1,1,1,1,1,1,1,1,1,1,1};  //initialize to pause
int8_t volatile actualState[11]       = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}; //initialize to unknown
uint8_t volatile debounceCntr[11] = {0,0,0,0,0,0,0,0,0,0,0};
#define DEBOUNCE_DELAY 100

/*
#define READ_ESTOP_STATE( num ) { if ( READ_VAL(RP_IN ## num ## _PORT,RP_IN ## num ## _PIN) ) \
                               { SET_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN); } \
                             else \
                             { CLEAR_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN); } \
                           }
*/


#define SHOW_COMMANDED_STATE( num ) { \
                                       switch (commandedState[num]) \
                                       { \
                                         case 0: \
                                           SET_OUTPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                           CLEAR_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN); \
                                           break; \
                                         case 1: \
                                           SET_INPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                           break; \
                                         case 2: \
                                           SET_OUTPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                           SET_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN);  \
                                           break; \
                                         default: \
                                           break; \
                                       } \
                                    }
                                
                            
#define SHOW_ACTUAL_STATE( num ) { \
                                   switch (actualState[num]) \
                                   { \
                                     case 0: \
                                       SET_OUTPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                       CLEAR_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN); \
                                       break; \
                                     case 1: \
                                       SET_INPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                       break; \
                                     case -1: \
                                     case 2: \
                                       SET_OUTPUT(LED_OUT ## num ## _DDR, LED_OUT ## num ## _PIN); \
                                       SET_PIN(LED_OUT ## num ## _PORT,LED_OUT ## num ## _PIN);  \
                                  } \
                                }
                               


#define CHECK_DISABLE_INPUT( num ) { if ( (READ_VAL(D_IN ## num ## _PORT,D_IN ## num ## _PIN)) ) \
                               { \
                                 commandedState[num] = 2; \
                               } \
                               else if (commandedState[num] == 2) \
                               { \
                                 commandedState[num] = 1; \
                               }\
                             }

#define READ_ESTOP_STATE( num ) { if ( (READ_VAL(RP_IN ## num ## _PORT,RP_IN ## num ## _PIN)) && debounceCntr[num] == DEBOUNCE_DELAY ) \
                             { \
                               if ( commandedState[num] == 1 )\
                                 commandedState[num] = 0; \
                               else if (commandedState[num]==0)\
                                 commandedState[num] = 1; \
                               debounceCntr[num] = 0; \
                             } \
                             if (debounceCntr[num] < DEBOUNCE_DELAY) debounceCntr[num]++; \
                             CHECK_DISABLE_INPUT(num); \
                           }



#define HOST_COM_BAUD_RATE 230400
#define XBEE_COM_BAUD_RATE 115200

int init()
{
  uart0_init();
  uart1_init();
  
  uart0_setbaud(HOST_COM_BAUD_RATE);
  uart1_setbaud(XBEE_COM_BAUD_RATE);
  
  //enable global interrupts 
  sei ();

  return 0;
}


void ShowCommandedStateAll()
{
  SHOW_COMMANDED_STATE(1);
  SHOW_COMMANDED_STATE(2);
  SHOW_COMMANDED_STATE(3);
  SHOW_COMMANDED_STATE(4);
  SHOW_COMMANDED_STATE(5);
  SHOW_COMMANDED_STATE(6);
  SHOW_COMMANDED_STATE(7);
  SHOW_COMMANDED_STATE(8);
  SHOW_COMMANDED_STATE(9);
  SHOW_COMMANDED_STATE(10);
}

void ShowActualStateAll()
{
  SHOW_ACTUAL_STATE(1);
  SHOW_ACTUAL_STATE(2);
  SHOW_ACTUAL_STATE(3);
  SHOW_ACTUAL_STATE(4);
  SHOW_ACTUAL_STATE(5);
  SHOW_ACTUAL_STATE(6);
  SHOW_ACTUAL_STATE(7);
  SHOW_ACTUAL_STATE(8);
  SHOW_ACTUAL_STATE(9);
  SHOW_ACTUAL_STATE(10);
}


int main(void)
{

  int c;
  int ret;
  uint8_t id;
  uint8_t type;
  uint8_t * data;
  int16_t cntr = 0;
  
  DDRA |= _BV(PA6) | _BV(PA7);
  DDRC = 0xFF;
  
  //PORTC= 0X00;

  int ii=0;
  uint8_t val = 1;
  
  init();
  
  uart0_printf("estop initialized\r\n");
  DynamixelPacket xbeePacket;
  DynamixelPacketInit(&xbeePacket);
  
  uint8_t robotId;
  uint8_t robotState;
  
  const int bufSize = 256;
  uint8_t buf[bufSize];
  uint8_t * pbuf;
  uint8_t estopPacketLen;
  
  const int nRobots = 9;
  uint8_t mode[nRobots+1] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  estopPacketLen = DynamixelPacketWrapData(MMC_ESTOP_DEVICE_ID,
           MMC_ESTOP_STATE,mode,nRobots+1,buf,bufSize);
           
  
  uint8_t modVal;
  
  while(1)
  {
    cntr++;
    if (cntr == 1000)
      cntr = 0;
    modVal = cntr % 200;
    
    if (modVal == 0)
    {
      //generate new packet based on the latest desired estop state
      estopPacketLen = DynamixelPacketWrapData(MMC_ESTOP_DEVICE_ID,
           MMC_ESTOP_STATE,commandedState,nRobots+1,buf,bufSize);
    
      pbuf = buf;
      for (ii=0; ii<estopPacketLen; ii++)
        uart1_putchar(*pbuf++);
      //uart0_printf("sent estop packet\r\n");
    }
    
    //show the actual status for brief moment
    if (modVal < 50)
    {
      ShowActualStateAll();
    }
    else
    {
      ShowCommandedStateAll();
    }
    
    
    
    //read from xbee
    while( (c = uart1_getchar()) != EOF )
    {
      //uart0_printf("%X ",c);;
      ret = DynamixelPacketProcessChar(c,&xbeePacket);
      if (ret > 0)
      {
        id   = DynamixelPacketGetId(&xbeePacket);
        type = DynamixelPacketGetType(&xbeePacket);
        data = DynamixelPacketGetData(&xbeePacket);
        
        if (id == MMC_ESTOP_DEVICE_ID && type == MMC_ESTOP_STATE)
        {
          robotId = data[0];
          robotState = data[1];
          
          if ( (robotId > 0) && (robotId < 11) && (robotState >= 0) && (robotState < 3) )
          {
            actualState[robotId] = robotState;
            uart0_printf("Robot%d: estop = %d\r\n",robotId,robotState);
          }
          else
            uart0_printf("xbee received bad data : Robot%d: estop = %d\r\n",robotId,robotState);
        }
      }
    }
    
  
    READ_ESTOP_STATE(1);
    READ_ESTOP_STATE(2);
    READ_ESTOP_STATE(3);
    READ_ESTOP_STATE(4);
    READ_ESTOP_STATE(5);
    READ_ESTOP_STATE(6);
    READ_ESTOP_STATE(7);
    READ_ESTOP_STATE(8);
    READ_ESTOP_STATE(9);
    READ_ESTOP_STATE(10);
    
    
    //check the master pause button
    if ( (READ_VAL(RP_IN0_PORT,RP_IN0_PIN)) && debounceCntr[0] == DEBOUNCE_DELAY )
    {
      if ( commandedState[0] == 1 )
      {
        for (ii=0; ii<11; ii++)
          commandedState[ii] = 0;
      }
      else if (commandedState[0]==0)
      {
        for (ii=0; ii<11; ii++)
          commandedState[ii] = 1;
      }
      debounceCntr[0] = 0;
    }
    if (debounceCntr[0] < DEBOUNCE_DELAY) 
      debounceCntr[0]++;
    
    SHOW_COMMANDED_STATE(0);
    
    
  /*
    if ( READ_VAL(RP_IN1_PORT,RP_IN1_PIN) )
      SET_PIN(LED_OUT1_PORT,LED_OUT1_PIN);
    else
      CLEAR_PIN(LED_OUT1_PORT,LED_OUT1_PIN);
   */   
  
    /*
    if (val == 0)
      DDRC=0x00;
      //val = 1;
    else 
      val = val << 1;
    PORTC = val;
    */
    
    //PORTC = PINL;
    
    _delay_ms(5);
  }
  

  return 0;
}
