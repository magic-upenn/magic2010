#include "SerialDevice.hh"
#include <string>
#include <string.h>
#include <iostream>
#include "MagicMicroCom.h"
#include "DynamixelPacket.h"
#include "Timer.hh"
#include <ipc.h>
#include "ErrorMessage.hh"
#include "IpcHelper.hh"
#include "MicroGateway2.hh"
#include "MagicSensorDataTypes.hh"
#include <math.h>
#include <stdlib.h>
#include <sstream>

using namespace std;
using namespace Upenn;
using namespace Magic;

#define MICRO_GATEWAY_MAX_NUM_IDS 256
#define MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID 256
#define MICRO_GATEWAY_MAX_NUM_MSGS MICRO_GATEWAY_MAX_NUM_IDS*MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID

//#define PRINT_IMU_FILTERED
//#define PRINT_IMU_RAW
//#define PRINT_GPS
#define PRINT_ENCODERS
//#define PRINT_SERVO

/////////////////////////////////////////////////////////////////////////
// Constructor
/////////////////////////////////////////////////////////////////////////
MicroGateway::MicroGateway()
{
  this->sd                  = NULL;
  this->connectedSerial     = false;
  this->connectedIPC        = false;
  
  this->inBufSerialSize     = MICRO_GATEWAY_SERIAL_INPUT_BUF_SIZE;
  this->outBufSerialSize    = MICRO_GATEWAY_SERIAL_OUTPUT_BUF_SIZE;

  this->inBufSerial         = new uint8_t[this->inBufSerialSize];
  this->outBufSerial        = new uint8_t[this->outBufSerialSize];
  
  
  this->inNumBufferedSerial = 0;
  this->inBufSerialPos      = this->inBufSerial;

  this->robotId             = -1;

  this->encoderTimer.Tic();


  this->vCmdPrev = 0;
  this->wCmdPrev = 0;
}


/////////////////////////////////////////////////////////////////////////
// Destructor
/////////////////////////////////////////////////////////////////////////
MicroGateway::~MicroGateway()
{
  if (this->sd)
  {
    this->sd->Disconnect();
    delete sd;
  }
  
  IPC_disconnect();
  this->connectedSerial = false;
  this->connectedIPC   = false;
}

/////////////////////////////////////////////////////////////////////////
// Connect to the Serial bus
/////////////////////////////////////////////////////////////////////////
int MicroGateway::ConnectSerial(char * dev, int baudRate)
{
  if (this->connectedSerial)
  {
    PRINT_INFO("Already connected to Serial bus\n");
    return 0;
  }
  
  //create instance of serial device
  this->sd = new SerialDevice();
  
  //try to connect
  int ret = this->sd->Connect(dev,baudRate);
  
  //check the return flag
  if (ret)
  {
    PRINT_ERROR("could not connect to the Serial bus\n");
    return -1;
  }
  
  this->sd->Set_IO_NONBLOCK_WO_TIMEOUT();
  this->connectedSerial = true;

  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Handler function for ipc messages
/////////////////////////////////////////////////////////////////////////
void MicroGateway::VelocityCmdMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData)
{
  
  //PRINT_INFO("got velocity cmd!\n");

  MicroGateway * mg      = (MicroGateway *)clientData;
  VelocityCmd * vcmd = (VelocityCmd*)callData;


  if (vcmd->vCmd > 127)
    vcmd->vCmd = 127;
  else if (vcmd->vCmd < -127)
    vcmd->vCmd = -127;

  if (vcmd->wCmd > 127)
    vcmd->wCmd = 127;
  else if (vcmd->wCmd < -127)
    vcmd->wCmd = -127;

  //filter
  mg->vCmdPrev = vcmd->vCmd;
  mg->wCmdPrev = vcmd->wCmd;

/*
  uint8_t cmd[] = {vcmd->vCmd, vcmd->wCmd,0,0};

  const int bufSize=256;
  uint8_t tempBuf[bufSize];

  uint8_t id   = MMC_MOTOR_CONTROLLER_DEVICE_ID;
  uint8_t type = MMC_MOTOR_CONTROLLER_VELOCITY_SETTING;

  int len = DynamixelPacketWrapData(id,type,cmd,4,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  mg->SendSerialPacket(tempBuf,len);
*/

  //free memory
  IPC_freeData(IPC_msgInstanceFormatter(msgRef),callData);
}

void MicroGateway::Laser0CmdMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData)
{
  
  

  MicroGateway * mg      = (MicroGateway *)clientData;
  uint8_t cmd = *((uint8_t*)callData);
  PRINT_INFO("got laser cmd! : "<<(int)cmd<<"\n");

  uint8_t id   = MMC_MAIN_CONTROLLER_DEVICE_ID;
  uint8_t type = MMC_MC_LASER0;

  const int bufSize=256;
  uint8_t tempBuf[bufSize];

  int len = DynamixelPacketWrapData(id,type,&cmd,1,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  mg->SendSerialPacket(tempBuf,len);

  //free memory
  IPC_freeByteArray(callData);
}

void MicroGateway::XbeeForwardMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData)
{
  MicroGateway * mg      = (MicroGateway *)clientData;
  uint8_t *data = (uint8_t*)callData;
  int msgLen  = IPC_dataLength(msgRef);

  PRINT_INFO("got xbee forward packet of size "<<msgLen<<"\n");

  uint8_t id   = MMC_XBEE_DEVICE_ID;
  uint8_t type = MMC_XBEE_FORWARD;

  const int bufSize=256;
  uint8_t tempBuf[bufSize];

  int len = DynamixelPacketWrapData(id,type,data,msgLen,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  mg->SendSerialPacket(tempBuf,len);

  //free memory
  IPC_freeByteArray(callData);
}


void MicroGateway::ServoControllerCmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData)
{
  
  MicroGateway * mg         = (MicroGateway *)clientData;
  ServoControllerCmd * scmd = (ServoControllerCmd*)callData;
  
  const int bufSize=32;
  uint8_t tempBuf1[bufSize];
  uint8_t tempBuf2[bufSize];

  float minAngle = scmd->minAngle;
  float maxAngle = scmd->maxAngle;
  float speed    = scmd->speed;

  tempBuf1[0] = scmd->mode;
  memcpy(tempBuf1+1,&(minAngle),sizeof(float));
  memcpy(tempBuf1+1+sizeof(float),&(maxAngle),sizeof(float));
  memcpy(tempBuf1+1+2*sizeof(float),&(speed),sizeof(float));

  int size;
  uint16_t a;
  uint16_t s;
  float angle;

  switch (scmd->id)
  {
    case 1:
      size = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                     MMC_MC_SERVO1_MODE,
                                     tempBuf1, 1+3*sizeof(float),
                                     tempBuf2,bufSize);
      
      if (size > 0)
      {
        mg->SendSerialPacket(tempBuf2,size);
        printf("sent servo command id=%d, mode=%d, min=%f, max=%f, speed=%f\n",
                scmd->id,scmd->mode,scmd->minAngle,scmd->maxAngle,scmd->speed);
      }
      else
        PRINT_ERROR("could not wrap packet\n");

      break;
      
    case 2:
      tempBuf1[0] = 0x1E;
      angle = minAngle;
      
      if ( (angle < -20 ) || (angle > 20 ) )
        angle = 0.0;
      #define DYNAMIXEL_MIN_ANGLE                -150
      #define DYNAMIXEL_MAX_ANGLE                 150
      #define DYNAMIXEL_AX12_MAX_RPM              114
      #define DYNAMIXEL_AX12_MAX_SPEED            (DYNAMIXEL_AX12_MAX_RPM/60.0*360.0)
      if ( (speed < 0) || (speed > DYNAMIXEL_AX12_MAX_SPEED) )
        speed = DYNAMIXEL_AX12_MAX_SPEED*0.5;

      a = ((angle-DYNAMIXEL_MIN_ANGLE)/(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE)*1023.0);
      s = (speed/DYNAMIXEL_AX12_MAX_SPEED*1023.0);
  
      //write the values into the packet
      memcpy(tempBuf1+1,&a,sizeof(uint16_t));
      memcpy(tempBuf1+3,&s,sizeof(uint16_t));
      
      
      
      size = DynamixelPacketWrapData(MMC_DYNAMIXEL1_DEVICE_ID,0x03,tempBuf1,5,tempBuf2,bufSize);
      
      if (size > 0)
      {
        mg->SendSerialPacket(tempBuf2,size);
        printf("sent laser servo command id=%d, angle =%f, speed=%f\n",
                MMC_DYNAMIXEL1_DEVICE_ID,angle,speed);
      }
      else
        PRINT_ERROR("could not wrap packet\n");

      break;


    default:
      PRINT_ERROR("invalid servo " << scmd->id << "\n");
      break;

   }
}


bool MicroGateway::ValidId(int id)
{
  if (id < 0 || id >= MICRO_GATEWAY_MAX_NUM_IDS)
    return false;
  return true;
}


int MicroGateway::PublishMsg(string msgName, void * data)
{
  if (IPC_publishData(msgName.c_str(),data) != IPC_OK)
    return -1;
  return 0;
}

/////////////////////////////////////////////////////////////////////////
// Generate the message name and register it with IPC
/////////////////////////////////////////////////////////////////////////
string MicroGateway::DefineMsg(string msgName, string format)
{
  string name = this->robotName + "/" + msgName;

  //register a new message with ipc
  if (IPC_defineMsg(name.c_str(),IPC_VARIABLE_LENGTH,
      format.c_str()) != IPC_OK)
  {
    PRINT_ERROR("could not define ipc message: " << name <<"\n");
    exit(1);
  }
  
  PRINT_INFO("Defined message "<<name<<" with format "<<format<<"\n");

  return name;
}

/////////////////////////////////////////////////////////////////////////
// Initialize the IPC messages before running the main loop
/////////////////////////////////////////////////////////////////////////
int MicroGateway::InitializeMessages()
{
  //define regular messages
  this->gpsMsgName           = this->DefineMsg("GPS",GpsASCII::getIPCFormat());
  this->encMsgName           = this->DefineMsg("Encoders",EncoderCounts::getIPCFormat());
  this->imuMsgName           = this->DefineMsg("ImuFiltered",ImuFiltered::getIPCFormat());
  this->estopMsgName         = this->DefineMsg("EstopState",EstopState::getIPCFormat());
  this->selectedIdMsgName    = this->DefineMsg("SelectedId","{byte}");
  this->servo1StateMsgName   = this->DefineMsg("Servo1",ServoState::getIPCFormat());
  this->batteryStatusMsgName = this->DefineMsg("BatteryStatus",BatteryStatus::getIPCFormat());
  this->motorStatusMsgName   = this->DefineMsg("MotorStatus",MotorStatus::getIPCFormat());
  this->xbeeMsgName          = this->DefineMsg("XbeeIncoming","");


  string msgName = this->robotName + "/" + "VelocityCmd";
  if (IPC_subscribeData(msgName.c_str(),this->VelocityCmdMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  PRINT_INFO("Subscribed to message "<<msgName<<"\n");

  msgName = this->robotName + "/" + "Servo1Cmd";
  if (IPC_subscribeData(msgName.c_str(),this->ServoControllerCmdMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  PRINT_INFO("Subscribed to message "<<msgName<<"\n");

  msgName = this->robotName + "/" + "Servo2Cmd";
  if (IPC_subscribeData(msgName.c_str(),this->ServoControllerCmdMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  PRINT_INFO("Subscribed to message "<<msgName<<"\n");

  msgName = this->robotName + "/" + "Laser0Cmd";
  if (IPC_subscribe(msgName.c_str(),this->Laser0CmdMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  PRINT_INFO("Subscribed to message "<<msgName<<"\n");

  msgName = this->robotName + "/" + "XbeeForward";
  if (IPC_subscribe(msgName.c_str(),this->XbeeForwardMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  PRINT_INFO("Subscribed to message "<<msgName<<"\n");

  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Connect to the IPC network
/////////////////////////////////////////////////////////////////////////
int MicroGateway::ConnectIPC(char * addr)
{

  if (this->connectedIPC)
  {
    PRINT_INFO("Already connected to IPC\n");
    return 0;
  }

  char * robotIdStr = getenv("ROBOT_ID");
  if (robotIdStr == NULL)
  {
    PRINT_ERROR("ROBOT_ID env variable is not defined\n");
    return -1;
  }

  this->robotId = strtol(robotIdStr,NULL,10);

  //double check if zero, since strtol will return 0 if conversion is invalid
  if ( (this->robotId == 0) && (strncmp(robotIdStr,"0",1) != 0))
  {
    PRINT_ERROR("ROBOT_ID env variable is invalid: "<<robotIdStr<<"\n");
    return -1;
  }

  //check the id
  if ( this->robotId < 0 || this->robotId > 255)
  {
    PRINT_ERROR("robot id is invalid: "<<this->robotId<<"\n");
    return -1;
  }

  //create the robot name
  stringstream ss;
  ss<<"Robot"<<this->robotId;
  this->robotName = ss.str();
  
  //connect to IPC
  IPC_setVerbosity(IPC_Print_Errors);
  
  //TODO: generate a unique name using IpcHelper
  if (IPC_connectModule("MicroGateway",addr) != IPC_OK)
  {
    PRINT_ERROR("could not connect to IPC central\n");
    return -1;
  }

  //subscribe to all the required message names
  if (this->InitializeMessages())
  {
    PRINT_ERROR("could not initialize ipc messages\n");
    return -1;
  }

  this->connectedIPC = true;
  
  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Send data to the serial bus
/////////////////////////////////////////////////////////////////////////
int MicroGateway::SendSerialPacket(uint8_t id, uint8_t type, uint8_t * buf,
                            uint8_t size)
{
  int ret;
  int outSize;
  
  //wrap the data into Dynamixel packet
  outSize = DynamixelPacketWrapData(id,type,buf,size,
            this->outBufSerial, this->outBufSerialSize);
        
  if (outSize < 0)
    return outSize;
  
  //write data to the serial port
  ret = this->SendSerialPacket(this->outBufSerial,outSize);

  return ret;
}

/////////////////////////////////////////////////////////////////////////
// Send data to the serial bus
/////////////////////////////////////////////////////////////////////////
int MicroGateway::SendSerialPacket(uint8_t * buf, uint8_t size)
{
  int ret = this->sd->WriteChars((char*)buf,size);
  if (ret < 0)
    PRINT_ERROR("could not send data to serial bus\n");

  return ret;
}


/////////////////////////////////////////////////////////////////////////
// Read data from the Serial bus
// This will be a non-blocking read and will pull all the data in the 
// serial buffer into the software buffer and then extract the first
// complete packet. If data for more than one packet was read, the
// first packet will be returned and the remaining data will be used
// during the next call
/////////////////////////////////////////////////////////////////////////
int MicroGateway::ReceiveSerialPacket(DynamixelPacket * dpacket, 
                                      double timeoutSec)
{
  int ret;
  int nchars;


  //check if there is any remaining data from the last read
  while (this->inNumBufferedSerial > 0)
  {
    //printf("."); fflush(stdout);
    ret = DynamixelPacketProcessChar(*this->inBufSerialPos++,dpacket);
    this->inNumBufferedSerial--;
    
    if (ret > 0)  //got a complete packet
      return ret;
  }
  
  //reset the buf pointer
  this->inBufSerialPos      = this->inBufSerial;
  this->inNumBufferedSerial = 0;

  //read chars without blocking
  nchars = this->sd->ReadChars((char*)this->inBufSerialPos, this->inBufSerialSize, 0);
  //nchars = this->sd->ReadChars((char*)this->inBufSerialPos, 10, 0);

  if (nchars <= 0)   //nothing received
    return nchars;
    
  //store the number of received characters
  this->inNumBufferedSerial = nchars;
  
  for (int ii=0; ii<nchars; ii++)
  {
    //printf("."); fflush(stdout);
    ret = DynamixelPacketProcessChar(*this->inBufSerialPos++,dpacket);
    this->inNumBufferedSerial--;
    
    if (ret > 0) //got a complete packet
      return ret;
  }

  //did not get a full packet yet
  return 0;
}



int MicroGateway::HandleSerialPacket(DynamixelPacket * dpacket)
{
  int deviceId = DynamixelPacketGetId(dpacket);

  switch (deviceId)
  {
    case MMC_MAIN_CONTROLLER_DEVICE_ID:
      this->MainControllerPacketHandler(dpacket);
      break;
    case MMC_MOTOR_CONTROLLER_DEVICE_ID:
      this->MotorControllerPacketHandler(dpacket);
      break;

    case MMC_GPS_DEVICE_ID:
      this->GpsPacketHandler(dpacket);
      break;

    case MMC_IMU_DEVICE_ID:
      this->ImuPacketHandler(dpacket);
      break;

    case MMC_RC_DEVICE_ID:
      this->RcPacketHandler(dpacket);
      break;

    case MMC_DYNAMIXEL0_DEVICE_ID:
    case MMC_DYNAMIXEL1_DEVICE_ID:
      this->ServoPacketHandler(dpacket);
      break;

    case MMC_ESTOP_DEVICE_ID:
      this->EstopPacketHandler(dpacket);
      break;

    case MMC_MASTER_DEVICE_ID:
      this->MasterPacketHandler(dpacket);

    case MMC_XBEE_DEVICE_ID:
      this->XbeePacketHandler(dpacket);
    default:
      break;
  }

  return 0;
}

int MicroGateway::XbeePacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket);
  int size       = DynamixelPacketGetPayloadSize(dpacket);
  
  printf("got xbee packet of size %d\n",size);

  if (IPC_publish(this->xbeeMsgName.c_str(),size,data) != IPC_OK)
  {
    PRINT_ERROR("could not publish ipc message\n");
    return -1;
  }  

  return 0;
}

int MicroGateway::MainControllerPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket);
  if (packetType == MMC_MC_VOLTAGE_BATT)
  {
    printf("got battery voltage %f\n",*((float*)data));
    BatteryStatus bs;
    bs.voltage = (double)*((float*)data);
    this->PublishMsg(this->batteryStatusMsgName,&bs);
  }
  return 0;
}


int MicroGateway::EstopPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  if (packetType == MMC_ESTOP_STATE)
  {
    EstopState estatePacket;
    estatePacket.t     = Upenn::Timer::GetAbsoluteTime();
    estatePacket.state = *(DynamixelPacketGetData(dpacket));
    this->PublishMsg(this->estopMsgName,&estatePacket);
    printf("got estop state %d\n",estatePacket.state); 
  }
  return 0;
}

int MicroGateway::GpsPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  if ( packetType == MMC_GPS_ASCII )
  {
#ifdef PRINT_GPS
    double gpsDt = this->gpsTimer.Toc();
    this->gpsTimer.Tic();
    //printf("got gps packet (%f) : ",gpsDt);
    char *c = (char*)DynamixelPacketGetData(dpacket);
    while (*c != '\n')
    {
      printf("%c",*c);
      c++;
    }
    printf("\n");
#endif
  }


  GpsASCII gpsPacket(Timer::GetAbsoluteTime(), 0,
                     DynamixelPacketGetPayloadSize(dpacket),
                     DynamixelPacketGetData(dpacket) );

  
  this->PublishMsg(this->gpsMsgName,&gpsPacket);

  return 0;
}



int MicroGateway::MotorControllerPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  //double motorDt = this->rs485timer.Toc();
  static Timer t0;
  static int cntr=0,en0=0,en1=0,en2=0,en3=0;

  if (packetType == MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE)
  {
    //this packet contains not only encoders, but also latest current for 2 hbridges
    //and raw temperatures from the two temperature sensors.
    cntr++;
    int16_t * encData = (int16_t*)DynamixelPacketGetData(dpacket);
    //printf("got encoder packet (%f) : ",this->encoderTimer.Toc());

    //PRINT_INFO("GOT encoders");

    en0 += encData[1];
    en1 += encData[2];
    en2 += encData[3];
    en3 += encData[4];

    if (cntr%40 == 0)
    {
      //double dt = t0.Toc(true); t0.Tic();
      
      MotorStatus ms;

      //conversion factor is with 0.008 ohm resistor, and 1/2 resistor divider on amplified signal
      const double currentScale = 1.0/1023.0*5.0/0.008/50.0*2;
      ms.currentRR = encData[5]*currentScale;
      ms.currentRL = encData[6]*currentScale;

      //temp sensor sould read 2.98V at 25C and 10mV/degree slope
      ms.tempRR = 25.0 + ( (encData[7]/1023.0*5.0) - 2.98)*100.0;
      ms.tempRL = 25.0 + ( (encData[8]/1023.0*5.0) - 2.98)*100.0;
      this->PublishMsg(this->motorStatusMsgName,&ms);
#ifdef PRINT_ENCODERS
      printf("encoders: %d %d %d %d\n",en0,en1,en2,en3);
      printf("current: %f %f\n",ms.currentRR,ms.currentRL);
      printf("temp: %f %f\n",ms.tempRR,ms.tempRL);
#endif
      en0 = en1 = en2 = en3 = 0;
    }


    EncoderCounts encPacket(Upenn::Timer::GetAbsoluteTime(),
                           (uint16_t)encData[0],encData[1],encData[2],encData[3], encData[4]);
    
    this->PublishMsg(this->encMsgName, &encPacket);

  }
  else if (DynamixelPacketGetType(dpacket) == MMC_MOTOR_CONTROLLER_VELOCITY_CONFIRMATION)
  {
    //printf("got velocity confirmation (%f) \n",motorDt);
  }

  return 0;
}

int MicroGateway::ImuPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);

  if (packetType == MMC_IMU_RAW)
  {

#ifdef PRINT_IMU_RAW
    int16_t * adcData = (int16_t*)DynamixelPacketGetData(dpacket);
    double imuDt = this->imuTimer.Toc();
    this->imuTimer.Tic();


    printf("got imu packet (%f) : ",imuDt);        
    for (int ii=0; ii<7; ii++)
      printf("%d ",adcData[ii]);
    printf("\n");
#endif 
  }
  

  
  else if (packetType == MMC_IMU_ROT)
  {
    float * fp = (float*)DynamixelPacketGetData(dpacket);
    ImuFiltered imu;
    imu.roll   = fp[0];
    imu.pitch  = fp[1];
    imu.yaw    = fp[2];
    imu.wroll  = fp[3];
    imu.wpitch = fp[4];
    imu.wyaw   = fp[5];
    imu.t      = Upenn::Timer::GetAbsoluteTime();


    //sanity check
    if ( (fabs(imu.wroll) > 2*M_PI) || (fabs(imu.wpitch) > 2*M_PI) || (fabs(imu.wyaw) > 2*M_PI) )
    {
      printf("bad angular rate!! rpy = %f %f %f\n",imu.wroll,imu.wpitch,imu.wyaw);
      return 0;
    }
   
    IPC_publishData(this->imuMsgName.c_str(),&imu);

#ifdef PRINT_IMU_FILTERED
    printf("got rot imu packet: %f %f %f %f %f %f\n",
               imu.roll*180/M_PI,imu.pitch*180/M_PI,imu.yaw*180/M_PI,
               imu.wroll*180/M_PI,imu.wpitch*180/M_PI,imu.wyaw*180/M_PI);
#endif
  }
  
  return 0;
}

int MicroGateway::RcPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  if (packetType == MMC_RC_DECODED)
    {
    /*
      uint16_t * data = (uint16_t*)DynamixelPacketGetData(dpacket);
    
      printf("got rc packet : ");
      for (int ii=0; ii<7; ii++)
        printf("%d ",data[ii]);
      printf("\n");
    */
    }

  return 0;
}

int MicroGateway::MasterPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  uint8_t * data = DynamixelPacketGetData(dpacket);
  uint8_t selectedId;

  switch (packetType)
  {
    case MMC_MASTER_ROBOT_SELECT:
      selectedId = *data;
      printf("Robot #%d has been selected\n",selectedId);
      IPC_publishData(this->selectedIdMsgName.c_str(),&selectedId);
      break;

    default:
      break;
  }
  
  return 0;
}

#define DYNAMIXEL_CONTROLLER_MIN_ANGLE              -150
#define DYNAMIXEL_CONTROLLER_MAX_ANGLE               150

int AngleVal2AngleDeg(uint16_t val, double &angle)
{
  angle = val/1023.0*(DYNAMIXEL_CONTROLLER_MAX_ANGLE-DYNAMIXEL_CONTROLLER_MIN_ANGLE) + DYNAMIXEL_CONTROLLER_MIN_ANGLE;
  return 0;
}

int MicroGateway::ServoPacketHandler(DynamixelPacket * dpacket)
{
  int id = DynamixelPacketGetId(dpacket);
  //int type = DynamixelPacketGetType(dpacket);
  int size = DynamixelPacketGetPayloadSize(dpacket);

  double angle;
  AngleVal2AngleDeg(*(uint16_t*)(dpacket->buffer+5),angle);

  if (size > 0)
  {

    Magic::ServoState sstate;
    sstate.position     = angle/180.0*M_PI;
    sstate.velocity     = 0;
    sstate.acceleration = 0;
    sstate.t            = Timer::GetUnixTime();
    sstate.id           = id;
    sstate.counter      = 0;

    if (IPC_publishData(this->servo1StateMsgName.c_str(),&sstate) != IPC_OK)
    {
      PRINT_ERROR("could not publish dynamixel message to ipc\n");
      return -1;
    }
  }

#ifdef PRINT_SERVO
  PRINT_INFO("got servo angle = "<<angle<<", type = "<<type<<", size = "<<size<<"\n");
#endif

 

  return 0;
}

int MicroGateway::ResetImu()
{
  const int bufSize=256;
  uint8_t * tempBuf = new uint8_t[bufSize];

  uint8_t id   = MMC_IMU_DEVICE_ID;
  uint8_t type = MMC_IMU_RESET;

  this->SendSerialPacket(id,type,NULL,0);
  delete [] tempBuf;

  return 0;
}

int MicroGateway::PrintSerialPacket(DynamixelPacket * dpacket)
{

  PRINT_INFO("got serial packet: ");
  
  for (int ii=0; ii<dpacket->lenExpected; ii++)
    printf("0x%02X ",dpacket->buffer[ii]);
  printf("\n");

  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Main function
/////////////////////////////////////////////////////////////////////////
int MicroGateway::Main()
{
  int ret;
  double serialRecTimeout = 0.1;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  uint16_t cnt =0;
  //uint16_t encoderCntr = 0;

  this->ResetImu();

  Timer t0;
  

  int vCmdPrev = 0;
  int wCmdPrev = 0;

  while(1)
  {
    cnt++;
    
    //receive serial data from the main microcontroller
    ret = this->ReceiveSerialPacket(&dpacket,serialRecTimeout);
    if (ret > 0)
    {      
      //this->PrintSerialPacket(&dpacket);

      this->HandleSerialPacket(&dpacket);
      //int deviceId = DynamixelPacketGetId(&dpacket);
    }
    else if (ret < 0)
      printf("serial error\n");


    //receive ipc messages
    IPC_listen(0);

    usleep(1000);

    if (t0.Toc() > 0.05)
    {
      t0.Tic();
      this->vCmdPrev*=0.9;
      this->wCmdPrev*=0.9;
      uint8_t cmd[] = {this->vCmdPrev, this->wCmdPrev,0,0};

      const int bufSize=256;
      uint8_t tempBuf[bufSize];

      uint8_t id   = MMC_MOTOR_CONTROLLER_DEVICE_ID;
      uint8_t type = MMC_MOTOR_CONTROLLER_VELOCITY_SETTING;

      int len = DynamixelPacketWrapData(id,type,cmd,4,tempBuf,bufSize);
      if (len < 0)
        PRINT_ERROR("could not wrap data\n");

      this->SendSerialPacket(tempBuf,len);
    }
  }

  return 0;
}


int MicroGateway::ReadConfig(uint16_t offset, uint8_t * data, uint16_t size)
{
  const int bufSize = 256;
  uint8_t buf[bufSize];
  uint8_t temp[256];
  memcpy(temp,&offset,2);
  memcpy(temp+2,&size,2);

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_EEPROM_READ,temp,4,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd->WriteChars((char*)buf,ret);

  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool readConfig = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd->ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * pdata = DynamixelPacketGetData(&dpacket);

        printf("got packet with id %d and type %d\n",id,type);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_EEPROM_READ)
          continue;

        gotResp = true;  

        uint16_t offset2;
        uint16_t size2;

        memcpy(&offset2,pdata,2);
        memcpy(&size2,pdata+2,2);

        if ((offset2 == offset) && (size2 == size))
          readConfig = true;

        memcpy(data,pdata+4,size);
      }
    }
  }

  if (readConfig)
    return size;
  else
    return -1;
}

int MicroGateway::WriteConfig(uint16_t offset, uint8_t * data, uint16_t size)
{
  const int bufSize = 256;
  uint8_t buf[bufSize];
  uint8_t temp[256];
  memcpy(temp,&offset,2);
  memcpy(temp+2,&size,2);
  memcpy(temp+4,data,size);

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_EEPROM_WRITE,temp,size+4,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd->WriteChars((char*)buf,ret);


  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool wroteConfig = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd->ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * pdata = DynamixelPacketGetData(&dpacket);

        printf("got packet with id %d and type %d\n",id,type);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_EEPROM_WRITE)
          continue;

        gotResp = true;  

        uint16_t offset2;
        uint16_t size2;

        memcpy(&offset2,pdata,2);
        memcpy(&size2,pdata+2,2);

        if ((offset2 == offset) && (size2 == size))
          wroteConfig = true;
      }
    }
  }

  if (wroteConfig)
    return 0;
  else
    return -1;
}

int MicroGateway::SwitchModeConfig()
{
  const int bufSize = 256;
  uint8_t buf[bufSize];
  uint8_t mode = MMC_MC_MODE_CONFIG;

  int ret = DynamixelPacketWrapData(MMC_MAIN_CONTROLLER_DEVICE_ID,
                                    MMC_MC_MODE_SWITCH,&mode,1,buf,bufSize);

  if (ret < 1)
  {
    PRINT_ERROR("could not wrap packet\n");
    return -1;
  }

  //write the mode switch request
  sd->WriteChars((char*)buf,ret);
  
  Timer t0; t0.Tic();

  bool gotResp      = false;
  bool switchedMode = false;
  char c;
  DynamixelPacket dpacket;
  DynamixelPacketInit(&dpacket);

  while (!gotResp && (t0.Toc() < 5))
  {
    int nchars = sd->ReadChars(&c,1);
    if (nchars==1)
    {
      int ret = DynamixelPacketProcessChar(c,&dpacket);
      if (ret > 0)
      {
        int id = DynamixelPacketGetId(&dpacket);
        int type = DynamixelPacketGetType(&dpacket);
        uint8_t * data = DynamixelPacketGetData(&dpacket);

        if (id != MMC_MAIN_CONTROLLER_DEVICE_ID)
          continue;
        if (type != MMC_MC_MODE_SWITCH)
          continue;

        gotResp = true;  

        if (*data == mode)
          switchedMode = true;
      }
    }
  }

  if (switchedMode)
    return 0;
  else
    return -1;
}

int MicroGateway::SwitchModeRun()
{

  return -1;
}

int MicroGateway::ReadPacket(DynamixelPacket * dpacket, double timeout)
{
  char c;
  int size;
  Timer t0; t0.Tic();
  DynamixelPacketInit(dpacket);

  bool gotPacket = false;
  while (!gotPacket && (t0.Toc() < timeout))
  {
    int nchars = sd->ReadChars(&c,1);
    if (nchars==1)
    {
      int size = DynamixelPacketProcessChar(c,dpacket);
      if (size > 0)
        gotPacket = true;
    }
  }

  if (gotPacket)
    return size;
  else
    return -1;
}



