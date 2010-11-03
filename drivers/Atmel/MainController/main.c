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
#include "uart3.h"
#include "timer1.h"
#include "timer3.h"
#include "timer4.h"
#include "attitudeFilter.h"
#include "ParamTable.h"
#include <avr/eeprom.h>
#include "Servo1Controller.h"

DynamixelPacket hostPacketIn;
DynamixelPacket busPacketIn;
DynamixelPacket motorCmdPacketOut;
DynamixelPacket xbeePacketIn;

#define encoderRequestRawPacketMaxSize 32
volatile uint8_t encoderRequestRawPacket[encoderRequestRawPacketMaxSize];
volatile uint8_t encoderRequestRawPacketSize = 0;

uint8_t servo1PacketOutBuf[32];
uint8_t servo1PacketOutBufSize = 0;

uint16_t adcVals[NUM_ADC_CHANNELS];
float rpy[3];
float wrpy[3];
float imuOutVals[7];

uint16_t adcCntr = 0;
uint16_t imuPacket[NUM_ADC_CHANNELS+1];

volatile uint8_t rs485Blocked           = 0;
volatile uint8_t needToSendMotorCmd     = 0;
volatile uint8_t needToRequestFb        = 0;
volatile uint8_t needToSendServo1Packet = 0;

uint8_t estopState                      = MMC_ESTOP_STATE_RUN;
volatile uint8_t freshMotorCmd          = 0;
volatile uint8_t mode                   = MMC_MC_MODE_RUN;



ParamTable EEMEM ptableE;
ParamTable ptableR;
uint8_t eepromTempData[sizeof(ParamTable)+4];

float voltageBatt                   = 0;
volatile uint8_t xbeeControl        = 0;
volatile uint32_t globalTimer       = 0;
volatile uint32_t lastXbeeCmdTime   = 0;
volatile uint32_t estopPublishTimer = 0;
volatile uint32_t estopTimeout      = 0;

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

inline void PutUInt16(uint16_t val)
{
  uint8_t * p = (uint8_t*)&val;
  HOST_COM_PORT_PUTCHAR(*(p+1));
  HOST_COM_PORT_PUTCHAR(*p);
}

void SendEstopStatus(void)
{
  HostSendPacket(MMC_ESTOP_DEVICE_ID,MMC_ESTOP_STATE,
                 (uint8_t*)&estopState,1);
}



void globalTimerOverflow(void)
{
  globalTimer += 0xFFFF; 
}

uint32_t GlobalTimerGetTime()
{
  uint32_t temp = globalTimer;
  uint16_t temp2 = TCNT3;
  return temp + temp2;
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
  LASER0_DDR        |= _BV(LASER0_PIN);
}


void SetBusBlocked()
{
  rs485Blocked = 1;
  TCNT4 = 0;
  timer4_enable_compa_callback();
}

void EncodersRequestFcn(void)
{
  needToRequestFb = 1;
  TCNT1 = 0;
}

void init(void)
{
  uint16_t dummy = 0;
  int16_t ret;

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
  
  XbeeInit();

  //timer for sending out estop status
  timer3_init();
  //timer3_set_overflow_callback(SendEstopStatus);
  timer3_set_overflow_callback(globalTimerOverflow);  

  timer4_init();
  timer4_set_compa_callback(Rs485ResponseTimeout);
  timer4_disable_compa_callback();

  timer1_init();
  timer1_set_compa_callback(EncodersRequestFcn);

  //generate the request packets:
  encoderRequestRawPacketSize = DynamixelPacketWrapData(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                          MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST,
                          &dummy,sizeof(dummy),
                          encoderRequestRawPacket,
                          encoderRequestRawPacketMaxSize);

  Servo1Init(GlobalTimerGetTime());


  //buzzer port
  BUZZER_DDR |= _BV(BUZZER_PIN);

  //enable global interrupts 
  sei();

  LED_ERROR_OFF;
}

/*
int ImuPacketHandler(uint8_t len)
{
  imuPacket[0] = adcCntr++;
  memcpy(&(imuPacket[1]),adcVals,NUM_ADC_CHANNELS*sizeof(uint16_t));
  HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_RAW,
                 (uint8_t*)imuPacket,(NUM_ADC_CHANNELS+1)*sizeof(uint16_t));
  return 0;
}
*/


int ReplyHostConfigReadDenied(uint8_t flag)
{
  return 0;
}

int ReplyHostConfigWriteDenied(uint8_t flag)
{
  return 0;
}

int HandleConfigReadRequest(DynamixelPacket * dpacket)
{
  uint8_t id   = DynamixelPacketGetId(dpacket);
  uint8_t type = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket); 
  uint16_t offset;
  uint16_t size;

  if ((id != MMC_MAIN_CONTROLLER_DEVICE_ID) || (type != MMC_MC_EEPROM_READ) )
    return -1;

  if (mode != MMC_MC_MODE_CONFIG)
    return -1;

  offset = *((uint16_t*)data);
  size   = *((uint16_t*)(data+2));
  
  if (offset + size > sizeof(ParamTable))
    return -1;
  

  //put the data into temporary packet
  memcpy(eepromTempData,&offset,sizeof(uint16_t));
  memcpy(eepromTempData+2,&size,sizeof(uint16_t));
  ReadParamTableBlock(offset,eepromTempData+4,size);
  
  //send the reply to host
  HostSendPacket(MMC_MAIN_CONTROLLER_DEVICE_ID,MMC_MC_EEPROM_READ, 
                  (uint8_t*)eepromTempData,size+4);
  
  return 0;
}

int HandleConfigWriteRequest(DynamixelPacket * dpacket)
{
  uint8_t id     = DynamixelPacketGetId(dpacket);
  uint8_t type   = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket); 
  uint16_t offset;
  uint16_t size;

  if ((id != MMC_MAIN_CONTROLLER_DEVICE_ID) || (type != MMC_MC_EEPROM_WRITE) )
    return -1;
  
  if (mode != MMC_MC_MODE_CONFIG)
    return -1;

  offset = *((uint16_t*)data);
  size   = *((uint16_t*)(data+2));
  
  if (offset + size > sizeof(ParamTable))
    return -1;
  
  WriteParamTableBlock(offset,data+4,size);

  memcpy(eepromTempData,&offset,sizeof(uint16_t));
  memcpy(eepromTempData+2,&size,sizeof(uint16_t));
  HostSendPacket(MMC_MAIN_CONTROLLER_DEVICE_ID,MMC_MC_EEPROM_WRITE,
                 (uint8_t*)eepromTempData,4);

  return 0;
}

int HandleModeSwitchRequest(DynamixelPacket * dpacket)
{
  uint8_t id     = DynamixelPacketGetId(dpacket);
  uint8_t type   = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket);

  if ((id != MMC_MAIN_CONTROLLER_DEVICE_ID) || (type != MMC_MC_MODE_SWITCH) )
    return -1;

  switch (*data)
  {
    case MMC_MC_MODE_IDLE:
    case MMC_MC_MODE_RUN:
    case MMC_MC_MODE_CONFIG:
      mode = *data;
      break;

    default:
      break;
  }

  //reply to the host
  HostSendPacket(MMC_MAIN_CONTROLLER_DEVICE_ID,MMC_MC_MODE_SWITCH,&mode,1);

  return 0;
}

int HostPacketHandler(DynamixelPacket * dpacket)
{
  uint8_t id   = DynamixelPacketGetId(dpacket);
  uint8_t type = DynamixelPacketGetType(dpacket);
  uint8_t * data;

  switch (id)
  {
    case MMC_MAIN_CONTROLLER_DEVICE_ID:
      switch(type)
      {
        case MMC_MC_RESET:
          //is software reset possible??
          break;

        case MMC_MC_MODE_SWITCH:
          HandleModeSwitchRequest(dpacket);
          break;

        case MMC_MC_EEPROM_READ:
          if (mode != MMC_MC_MODE_CONFIG)
            ReplyHostConfigReadDenied(0);
          else
            HandleConfigReadRequest(dpacket);
          break;

        case MMC_MC_EEPROM_WRITE:
          if (mode != MMC_MC_MODE_CONFIG)
            ReplyHostConfigWriteDenied(0);
          else
            HandleConfigWriteRequest(dpacket);
          break;

        case MMC_MC_SERVO1_MODE:
          data = DynamixelPacketGetData(dpacket);
          Servo1SetMinAngle(*((float*)(data+1)));
          Servo1SetMaxAngle(*((float*)(data+5)));
          Servo1SetSpeed(*((float*)(data+9)));
          Servo1SetMode(*data);
          break;

        case MMC_MC_LASER0:
          data = DynamixelPacketGetData(dpacket);
          if (*data == 0)
            LASER0_OFF;
          else
            LASER0_ON;
          break;

        default:
          break;
      }
      break;

    case MMC_IMU_DEVICE_ID:
      switch(type)
      {
        case MMC_IMU_RESET:
          ResetImu();
          break;

      }
      break;


    case MMC_MOTOR_CONTROLLER_DEVICE_ID:
      if ((GlobalTimerGetTime() - lastXbeeCmdTime) > 200000)   //200000*16uS per tic = 3.2 seconds time out
        xbeeControl = 0;

      if (xbeeControl == 1)    //if xbee control is enabled, don't send anything through to the motor controller
        break;
      if ( (type == MMC_MOTOR_CONTROLLER_VELOCITY_SETTING) && (estopState == MMC_ESTOP_STATE_RUN) )
      {
        if (rs485Blocked)
        {
          DynamixelPacketCopy(&motorCmdPacketOut,dpacket);
          needToSendMotorCmd = 1;
        }
        else
          BusSendRawPacket(dpacket);  //does not require a response, so bust won't be blocked
      }
      break;

    case MMC_XBEE_DEVICE_ID:
      if (type == MMC_XBEE_FORWARD)
        XbeeSendRawPacket(dpacket);
      break;

    default:
      break;
  }

  cli();
  LED_PC_ACT_TOGGLE;
  sei();   

  return 0;
}

int BusPacketHandler(DynamixelPacket * packet)
{
  uint8_t id = DynamixelPacketGetId(packet);
  //disable the timeout for RS485 bus, since the response came back
  timer4_disable_compa_callback();
  rs485Blocked = 0;
  HostSendRawPacket(packet);

  
  if ( (id == MMC_MOTOR_CONTROLLER_DEVICE_ID) && (needToSendMotorCmd == 1))
  {
    BusSendRawPacket(&motorCmdPacketOut);
    needToSendMotorCmd = 0;
  }
  
  
  return 0;
}

int GpsPacketHandler(uint8_t * buf, uint8_t len)
{
  LED_GPS_TOGGLE;
  HostSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_ASCII, buf,len);
  //XbeeSendPacket(MMC_GPS_DEVICE_ID,MMC_GPS_ASCII, buf,len);
  //XBEE_COM_PORT_PRINTF("got gps on robot 2 %d\r\n",TCNT3);

  return 0;
}

int DisableVehicle()
{
  LED_ESTOP_OFF;
  HostSendPacket(MMC_ESTOP_DEVICE_ID,MMC_ESTOP_STATE,
                 (uint8_t*)&estopState,1);
          
  //disable all interrupts and enter endless loop
  cli();
  while(1) { _delay_ms(100); }

  return 0;
}


int XbeePacketHandler(DynamixelPacket * dpacket)
{
  uint8_t id   = DynamixelPacketGetId(dpacket);
  uint8_t type = DynamixelPacketGetType(dpacket);
  uint8_t size = DynamixelPacketGetPayloadSize(dpacket);
  uint8_t * data;
  uint8_t newEstopState;
  
  LED_RC_TOGGLE;
  
  if ( (id == MMC_ESTOP_DEVICE_ID) && (type == MMC_ESTOP_STATE))
  {
    if (size < ptableR.id)
      return -1;
      
    newEstopState = data[ptableR.id];
      
      
    if ( !(newEstopState == MMC_ESTOP_STATE_RUN ||
           newEstopState == MMC_ESTOP_STATE_FREEZE ||
           newEstopState == MMC_ESTOP_STATE_DISABLE) )
      return -1;
  
    estopState   = newEstopState;
    estopTimeout = GlobalTimerGetTime();
    
    switch (estopState)
    {
      case MMC_ESTOP_STATE_RUN:
        LED_ESTOP_ON;
        break;
      case MMC_ESTOP_STATE_FREEZE:
        LED_ESTOP_OFF;
        break;
      case MMC_ESTOP_STATE_DISABLE:
        DisableVehicle();
        break;
      default:
        break;
    }
  }
  
  /*
  //XbeeSendPacket(0,0,NULL,0);
  
  XbeePacketHandler(&dpacket);
  if (DynamixelPacketGetId(&dpacket) == MMC_MOTOR_CONTROLLER_DEVICE_ID)
  {
    lastXbeeCmdTime = GlobalTimerGetTime();
    xbeeControl = 1;
    DynamixelPacketCopy(&motorCmdPacketOut,&xbeePacketIn);
    needToSendMotorCmd = 1;
  }
  else
    HostSendRawPacket(&xbeePacketIn);
  */
}


int LoadAndSetEepromParams()
{
  ReadParamTableBlock(0,&ptableR,sizeof(ParamTable));
  SetImuAccBiases(ptableR.accBiasX,ptableR.accBiasY,ptableR.accBiasZ);
  return 0;
}

int main(void)
{
  int16_t len;
  uint8_t * buf;
  int c;
  int imuRet;
  int ret;

  uint8_t * servo1PacketOut        = NULL;
  DynamixelPacket * servo1PacketIn = NULL;
  uint8_t servo1PacketOutSize      = 0;
  float servo1Angle;
  uint32_t servo1Time;
  uint32_t newEstopTime;
  
  estopState = MMC_ESTOP_STATE_RUN;
  LED_ESTOP_ON;
  
  estopPublishTimer  = GlobalTimerGetTime();
  estopTimeout       = GlobalTimerGetTime();
  
  DynamixelPacketInit(&hostPacketIn);
  DynamixelPacketInit(&busPacketIn);
  DynamixelPacketInit(&xbeePacketIn);

  if (LoadAndSetEepromParams() != 0)
  {
    while(1)
    {
      //TODO: send the error packet
      _delay_ms(100);
    }
  }

  init();

  //Servo1SetMode(SERVO_CONTROLLER_MODE_FB_ONLY);
  //Servo1SetMode(SERVO_CONTROLLER_MODE_SERVO);
  
  while(1)
  {
    //receive packet from host
    len=HostReceivePacket(&hostPacketIn);
    if ( (len>0) && (estopState == MMC_ESTOP_STATE_RUN) )
      HostPacketHandler(&hostPacketIn);

    if (mode == MMC_MC_MODE_CONFIG)
      continue;


//--------------------------------------------------------------------
//                      Estop Stuff
//--------------------------------------------------------------------

    //check the state of the estop input
    if (ESTOP_PORT & _BV(ESTOP_PIN))   //input high means disabled
    {
      estopState = MMC_ESTOP_STATE_DISABLE;
      DisableVehicle();
    }
    
    //see if we need to send out estop status
    newEstopTime = GlobalTimerGetTime();
    if (newEstopTime > (estopPublishTimer+50000))   //0.8 seconds
    {
      HostSendPacket(MMC_ESTOP_DEVICE_ID,MMC_ESTOP_STATE,
                     (uint8_t*)&estopState,1);
      estopPublishTimer = newEstopTime;
    }
    
    if (newEstopTime > (estopTimout + 625000))     //10 seconds
    {
      estopState = MMC_ESTOP_STATE_FREEZE;
    }
     

//--------------------------------------------------------------------
//                        RS-485 Bus
//--------------------------------------------------------------------

    //receive packet from RS485 bus
    servo1PacketIn = NULL;
    len=BusReceivePacket(&busPacketIn);
    if (len>0)
    {
      if (DynamixelPacketGetId(&busPacketIn) == MMC_DYNAMIXEL0_DEVICE_ID)
        servo1PacketIn = &busPacketIn;
      
      BusPacketHandler(&busPacketIn);
    }


//--------------------------------------------------------------------
//                      Servo Controller
//--------------------------------------------------------------------
    
    Servo1UpdateTime(GlobalTimerGetTime());
    Servo1Update(servo1PacketIn,&servo1PacketOut,&servo1PacketOutSize);
    
    if (servo1PacketOut && (servo1PacketOutSize > 0) && (estopState == MMC_ESTOP_STATE_RUN) )
    {
      memcpy(servo1PacketOutBuf,servo1PacketOut,servo1PacketOutSize);
      servo1PacketOutBufSize = servo1PacketOutSize;
    
      needToSendServo1Packet = 1;
    }


//--------------------------------------------------------------------
//                              Xbee
//--------------------------------------------------------------------

    len = XbeeReceivePacket(&xbeePacketIn);
    if (len > 0)
      XbeePacketHandler(&xbeePacketIn);
    
    
//--------------------------------------------------------------------
//                              GPS
//--------------------------------------------------------------------    
    //receive a line from gps
    len=GpsReceiveLine(&buf);
    if (len>0)
      GpsPacketHandler(buf,len);
      
      
      
//--------------------------------------------------------------------
//                              ADC
//--------------------------------------------------------------------

    cli();
    len = adc_get_data(adcVals);
    sei();    

    if (len > 0)
    {
      adcCntr++;
      imuRet = ProcessImuReadings(adcVals,rpy,wrpy);
      if (imuRet == 0) //will return 0 if updated, 1 if not yet updated
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
      else if (imuRet == 1)    //send out raw values if calibration is not finished
      {
        imuPacket[0] = adcCntr;
        memcpy(&(imuPacket[1]),adcVals,NUM_ADC_CHANNELS*sizeof(uint16_t));
        HostSendPacket(MMC_IMU_DEVICE_ID,MMC_IMU_RAW,
		       (uint8_t*)imuPacket,(NUM_ADC_CHANNELS+1)*sizeof(uint16_t));
      }

      if (adcCntr % 100 == 0)
      {
        voltageBatt = adcVals[6]/1024.0*2.56*(11.0);
        HostSendPacket(MMC_MAIN_CONTROLLER_DEVICE_ID,MMC_MC_VOLTAGE_BATT,
	                     (uint8_t*)(&voltageBatt),sizeof(float));

        if (voltageBatt < 21.0)
        {
          cli();  BUZZER_ON; sei();
        }
        else
        {
          cli(); BUZZER_OFF; sei();
        }
      }
    }


//--------------------------------------------------------------------
//                       RS485 Bus Handling
//--------------------------------------------------------------------

    if ( (needToSendServo1Packet == 1) && (rs485Blocked == 0))
    {
      SetBusBlocked();
      BusSendRawData(servo1PacketOutBuf,servo1PacketOutBufSize);
      needToSendServo1Packet = 0;
      TCNT1 = 12500/4;
    }

    if ( (needToRequestFb == 1) && (rs485Blocked == 0) )
    {
      SetBusBlocked();
      BusSendRawData(encoderRequestRawPacket,encoderRequestRawPacketSize);
      needToRequestFb = 0;
    }  
 }

  

  return 0;
}
