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
//#define PRINT_ENCODERS
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

  uint8_t cmd[] = {vcmd->vCmd, vcmd->wCmd,0,0};

  const int bufSize=256;
  uint8_t tempBuf[bufSize];

  uint8_t id   = MMC_MOTOR_CONTROLLER_DEVICE_ID;
  uint8_t type = MMC_MOTOR_CONTROLLER_VELOCITY_SETTING;

  int len = DynamixelPacketWrapData(id,type,cmd,4,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  mg->SendSerialPacket(tempBuf,len);

  //free memory
  IPC_freeData(IPC_msgInstanceFormatter(msgRef),callData);
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

    default:
      PRINT_ERROR("invalid servo id\n");
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
  this->gpsMsgName   = this->DefineMsg("GPS",GpsASCII::getIPCFormat());
  this->encMsgName   = this->DefineMsg("Encoders",EncoderCounts::getIPCFormat());
  this->imuMsgName   = this->DefineMsg("ImuFiltered",ImuFiltered::getIPCFormat());
  this->estopMsgName = this->DefineMsg("EstopState",EstopState::getIPCFormat());
  this->selectedIdMsgName  = this->DefineMsg("SelectedId","{byte}");
  this->servo1StateMsgName = this->DefineMsg("Servo1",ServoState::getIPCFormat());


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
    default:
      break;
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
    double gpsDt = this->gpsTimer.Toc();
    this->gpsTimer.Tic();

#ifdef PRINT_GPS
    printf("got gps packet (%f) : ",gpsDt);
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

  if (packetType == MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE)
  {
    int16_t * encData = (int16_t*)DynamixelPacketGetData(dpacket);
    //printf("got encoder packet (%f) : ",this->encoderTimer.Toc());
#ifdef PRINT_ENCODERS
    //PRINT_INFO("GOT encoders");
    double dt = t0.Toc(true); t0.Tic();
    printf("encoders: %d %d %d %d %d\n",(uint16_t)encData[0],encData[1],encData[2],encData[3], encData[4]);
    if (dt < 1 && dt > 0.03)
    {
      printf("!!!!!!!!!!!!!!!!!\n");
      //exit(1);
    }
#endif
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
  int type = DynamixelPacketGetType(dpacket);
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
  uint16_t encoderCntr = 0;

  this->ResetImu();

  while(1)
  {
    cnt++;
    
    //receive serial data from the main microcontroller
    ret = this->ReceiveSerialPacket(&dpacket,serialRecTimeout);
    if (ret > 0)
    {      
      //this->PrintSerialPacket(&dpacket);

      this->HandleSerialPacket(&dpacket);
      
      int deviceId = DynamixelPacketGetId(&dpacket);
    }
    else if (ret < 0)
      printf("serial error\n");


    //receive ipc messages
    IPC_listen(0);

    usleep(1000);
  }

  return 0;
}

