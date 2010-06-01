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
#include "MicroGateway.hh"
#include "MagicSensorDataTypes.hh"
#include "MagicMicroCom.h"
#include <math.h>
#include <stdlib.h>
#include <sstream>

using namespace std;
using namespace Upenn;
using namespace Magic;

#define MICRO_GATEWAY_MAX_NUM_IDS 256
#define MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID 256
#define MICRO_GATEWAY_MAX_NUM_MSGS MICRO_GATEWAY_MAX_NUM_IDS*MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID

struct Rs485ToIpcMsg
{
  int id;
  int type;
  const char * name;
};

struct Rs485Msg
{
  int id;
};

struct Rs485WaitResponseMsg
{
  int id;
  int type;
};

struct IpcToRs485Msg
{
  const char * name;
};

Rs485ToIpcMsg rs485ToIpcMsgs[] =
{ 
  { MMC_MOTOR_CONTROLLER_DEVICE_ID,MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE, "Encoders_in"},
  { MMC_IMU_DEVICE_ID,        MMC_IMU_ROT,   "IMU_in"            },
  { MMC_IMU_DEVICE_ID,        MMC_IMU_RAW,   "IMU_RAW_in"        },
  { MMC_IMU_DEVICE_ID,        MMC_MAG_RAW,   "IMU_MAG_RAW_in"    },
  { MMC_GPS_DEVICE_ID,        MMC_GPS_ASCII, "GPS_RAW_in"        },
  { MMC_DYNAMIXEL0_DEVICE_ID, -1,            "Dynamixel0_in"     },
  { MMC_DYNAMIXEL1_DEVICE_ID, -1,            "Dynamixel1_in"     }
};


Rs485Msg rs485Msgs[] =
{ 
  { MMC_MOTOR_CONTROLLER_DEVICE_ID },
  { MMC_DYNAMIXEL0_DEVICE_ID       },
  { MMC_DYNAMIXEL1_DEVICE_ID       }
};

Rs485WaitResponseMsg rs485WaitResponseMsgs[] =
{
  { MMC_MOTOR_CONTROLLER_DEVICE_ID, MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST }
};

IpcToRs485Msg ipcToRs485Msgs[] =
{
  { "Dynamixel0_out"      },
  { "Dynamixel1_out"      },
  { "MotorController_out" }
};


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

  this->reggedMsgTypes      = new int[MICRO_GATEWAY_MAX_NUM_MSGS];
  this->wait485Response     = new int[MICRO_GATEWAY_MAX_NUM_MSGS];
  this->idsOn485Bus         = new int[MICRO_GATEWAY_MAX_NUM_IDS];
  
  this->waitingRS485Resp    = false;

  this->msgNames.resize(MICRO_GATEWAY_MAX_NUM_MSGS,"");
  
  //initialize the message tables to zeros
  memset(this->reggedMsgTypes,0,MICRO_GATEWAY_MAX_NUM_MSGS*sizeof(int));
  memset(this->wait485Response,0,MICRO_GATEWAY_MAX_NUM_MSGS*sizeof(int));
  memset(this->idsOn485Bus,0,MICRO_GATEWAY_MAX_NUM_IDS*sizeof(int));

  this->encoderUpdateTime = MICRO_GATEWAY_ENCODER_UPDATE_TIME;
  this->encoderTimer.Tic();

  this->dynamixelControllers.push_back(new DynamixelController());
  this->dynamixelControllers[0]->SetId(MMC_DYNAMIXEL0_DEVICE_ID);
  this->dynamixelControllers[0]->SetMinLimit(SERVO1_MIN_LIMIT_DEG);
  this->dynamixelControllers[0]->SetMaxLimit(SERVO1_MAX_LIMIT_DEG);
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

  delete [] this->reggedMsgTypes;
  delete [] this->wait485Response;
  delete [] this->idsOn485Bus;
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
  uint8_t * tempBuf = new uint8_t[bufSize];

  uint8_t id   = MMC_MOTOR_CONTROLLER_DEVICE_ID;
  uint8_t type = MMC_MOTOR_CONTROLLER_VELOCITY_SETTING;

  int len = DynamixelPacketWrapData(id,type,cmd,4,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  mg->PushRS485Queue(tempBuf,len,
                     mg->NeedToWaitForRS485Response(id,type),true);

  //free memory
  IPC_freeData(IPC_msgInstanceFormatter(msgRef),callData);
}

void MicroGateway::ServoControllerCmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData)
{
  MicroGateway * mg         = (MicroGateway *)clientData;
  ServoControllerCmd * scmd = (ServoControllerCmd*)callData;
  DynamixelController * dcntrl = NULL;

  switch (scmd->id)
  {
    case 1:
      dcntrl = mg->dynamixelControllers[0];
      break;

    default:
      break;
  }

  if (dcntrl)
  {
    dcntrl->SetMinAngle(scmd->minAngle);
    dcntrl->SetMaxAngle(scmd->maxAngle);
    dcntrl->SetSpeed(scmd->speed);
    dcntrl->SetAcceleration(scmd->acceleration);
    dcntrl->SetMode(scmd->mode);
    dcntrl->ResetState();
  }
}

/////////////////////////////////////////////////////////////////////////
// Handler function for ipc messages
/////////////////////////////////////////////////////////////////////////
void MicroGateway::IpcMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData)
{
  
  //PRINT_INFO("GOT IPC MESSAGE\n");

  MicroGateway * mg      = (MicroGateway *)clientData;
  IpcRawDynamixelPacket * ipacket = (IpcRawDynamixelPacket*)callData; 

  //check the packet size
  if (ipacket->size < 0 || ipacket->size > 255)
  {
    PRINT_ERROR("bad packet size: "<<ipacket->size<<"\n");
    //free memory
    IPC_freeData(IPC_msgInstanceFormatter(msgRef),callData);
    return;
  }
  
  //if the packet is going out on the rs485 bus, treat it appropriately
  int id   = DynamixelPacketRawGetId(ipacket->data);
  int type = DynamixelPacketRawGetType(ipacket->data);
  
  //see if the device id is on the 485 bus
  int idOn485Bus = mg->OnRS485Bus(id);
  uint8_t * tempBuf;
  
  switch (idOn485Bus)
  {
    case 0:
      //write the packet directly to the serial port
      if (mg->SendSerialPacket(ipacket->data,(uint8_t)ipacket->size) < 0)
        PRINT_ERROR("could not send packet\n");
      break;
      
    case 1:
      //add the message to the RS485 queue
      
      tempBuf = new uint8_t[ipacket->size];  //this will be freed when packet is sent
      memcpy(tempBuf,ipacket->data,ipacket->size);

      mg->PushRS485Queue(tempBuf,ipacket->size,
                         mg->NeedToWaitForRS485Response(id,type),true);

      //PRINT_INFO("PUSHED PACKET INTO THE QUEUE\n");
      break;
      
    default:
      PRINT_ERROR("could not check whether the id is on RS485 bus");
      break;
  }

  //free memory
  IPC_freeData(IPC_msgInstanceFormatter(msgRef),callData);
}

bool MicroGateway::ValidId(int id)
{
  if (id < 0 || id >= MICRO_GATEWAY_MAX_NUM_IDS)
    return false;
  return true;
}

int MicroGateway::OnRS485Bus(int id)
{
  if (!this->ValidId(id))
  {
    PRINT_ERROR("invalid id\n");
    return -1;
  }
  
  return this->idsOn485Bus[id];
}

bool MicroGateway::NeedToWaitForRS485Response(int id, int type)
{
  int idx = this->IdType2Ind(id,type);
  
  return this->NeedToWaitForRS485Response(idx);
}

bool MicroGateway::NeedToWaitForRS485Response(int idx)
{
  if (idx < 0 || idx >= MICRO_GATEWAY_MAX_NUM_MSGS)
  {
    PRINT_ERROR("bad message index\n");
    return false;
  }
  
  if (this->wait485Response[idx])
    return true;

  return false;

}

bool MicroGateway::NeedToWaitForRS485Response(uint8_t * rawPacket)
{
  int id   = DynamixelPacketRawGetId(rawPacket);
  int type = DynamixelPacketRawGetType(rawPacket);
  
  return this->NeedToWaitForRS485Response(id,type);
}

/////////////////////////////////////////////////////////////////////////
// Calculate the message index for looking up the name
/////////////////////////////////////////////////////////////////////////
int MicroGateway::IdType2Ind(int id, int type)
{
  if (id < 0 || id >= MICRO_GATEWAY_MAX_NUM_IDS)
  {
    PRINT_ERROR("bad id : "<<id<<"\n");
    return -1;
  }
  
  if (type < 0 || type >= MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID)
  {
    PRINT_ERROR("bad type : "<<type<<"\n");
    return -1;
  }
  
  int idx = id * MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID + type;
  
  return idx;
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
// Generate the message name and register it with IPC
/////////////////////////////////////////////////////////////////////////
string MicroGateway::DefineMsg(int id, int type, string msgName)
{
  int idx = this->IdType2Ind(id,type);
  if (idx < 0)
  {
    PRINT_ERROR("bad message index\n");
    exit(1);
  }
  
  this->reggedMsgTypes[idx] = 1;
  this->msgNames[idx] = this->robotName + "/" + msgName;
  
  //don't redefine messages with IPC (though it would not be an error)
  if (IPC_isMsgDefined(this->msgNames[idx].c_str()))
    return string();
  
  //register a new message with ipc
  if (IPC_defineMsg(this->msgNames[idx].c_str(),IPC_VARIABLE_LENGTH,
      IpcRawDynamixelPacket::getIPCFormat()) != IPC_OK)
  {
    PRINT_ERROR("could not define ipc message: " << this->msgNames[idx] <<"\n");
    exit(1);
  }
  
  PRINT_INFO("Defined message "<<this->msgNames[idx]<<" with id "<<id<<" type "<<type<<"\n");

  return this->msgNames[idx];
}

/////////////////////////////////////////////////////////////////////////
// Subscribe to ipc message
/////////////////////////////////////////////////////////////////////////
int MicroGateway::SubscribeMsg(string msgName)
{
  string newMsgName = this->robotName + "/" + msgName;
  if (IPC_subscribeData(newMsgName.c_str(),this->IpcMsgHandler,this) != IPC_OK)
  {
    PRINT_ERROR("could not subscribe to IPC message\n");
    exit(1);
  }
  
  PRINT_INFO("Subscribed to message "<<newMsgName<<"\n");
  
  return 0;
}

/////////////////////////////////////////////////////////////////////////
// Fill in the message ids that require waiting for response
/////////////////////////////////////////////////////////////////////////
int MicroGateway::AddWaitFor485Response(int id, int type)
{
  int idx = this->IdType2Ind(id,type);
  if (idx < 0)
  {
    PRINT_ERROR("bad message index\n");
    exit(1);
    //return -1;
  }
  
  this->wait485Response[idx] = 1;
  //PRINT_INFO("Added response wait for id "<<id<<" type "<<type<<"\n");
  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Initialize the IPC messages before running the main loop
/////////////////////////////////////////////////////////////////////////
int MicroGateway::InitializeMessages()
{
  //define regular messages
  this->gpsMsgName = this->DefineMsg("GPS",GpsASCII::getIPCFormat());
  this->encMsgName = this->DefineMsg("Encoders",EncoderCounts::getIPCFormat());
  this->dynamixelIpcMsgNames.push_back(this->DefineMsg("Servo1",ServoState::getIPCFormat()));
  this->imuMsgName = this->DefineMsg("ImuFiltered",ImuFiltered::getIPCFormat());

  //define all messages that this process will send out via IPC
  this->DefineMsg(MMC_MOTOR_CONTROLLER_DEVICE_ID, 
                  MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE,
                  "Encoders_in");
                  
  this->DefineMsg(MMC_IMU_DEVICE_ID, MMC_IMU_ROT,   "IMU_in");
  this->DefineMsg(MMC_IMU_DEVICE_ID, MMC_IMU_RAW,   "IMU_RAW_in");
  this->DefineMsg(MMC_GPS_DEVICE_ID, MMC_GPS_ASCII, "GPS_RAW_in");
  this->DefineMsg(MMC_IMU_DEVICE_ID, MMC_MAG_RAW,   "MAG_RAW_in");
  
 /* 
  //define all messages for the dynamixel servo
  for (int ii=0; ii<MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID; ii++)
  {
    this->DefineMsg(MMC_DYNAMIXEL0_DEVICE_ID, ii,   "Dynamixel0_in");
    this->AddWaitFor485Response(MMC_DYNAMIXEL0_DEVICE_ID,ii);
  }

  //define all messages for the dynamixel servo
  for (int ii=0; ii<MICRO_GATEWAY_MAX_NUM_TYPES_PER_ID; ii++)
  {
    this->DefineMsg(MMC_DYNAMIXEL1_DEVICE_ID, ii,   "Dynamixel1_in");
    this->AddWaitFor485Response(MMC_DYNAMIXEL1_DEVICE_ID,ii);
  }
  */ 
    
    
  //this->AddWaitFor485Response(MMC_MOTOR_CONTROLLER_DEVICE_ID,
  //                         MMC_MOTOR_CONTROLLER_VELOCITY_SETTING);
  this->AddWaitFor485Response(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                           MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST);
                           
                           
  //add the ids that are on 485 bus
  //this will be used to figure out that the response has been received
  //and it's ok to send another message to a device on 485 bus
  this->AddIdOn485Bus(MMC_MOTOR_CONTROLLER_DEVICE_ID);
  this->AddIdOn485Bus(MMC_DYNAMIXEL0_DEVICE_ID);
  this->AddIdOn485Bus(MMC_DYNAMIXEL1_DEVICE_ID);
  
  
  //subscribe to all messages that this process will forward onto 
  //the rs485 bus
  //this->SubscribeMsg("Dynamixel0_out");
  //this->SubscribeMsg("Dynamixel1_out");
  this->SubscribeMsg("MotorController_out");


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
// Add an id to the list of ids that are on the RS485 bus
/////////////////////////////////////////////////////////////////////////
int MicroGateway::AddIdOn485Bus(int id)
{
  if (id < 0 || id >= MICRO_GATEWAY_MAX_NUM_IDS)
  {
    PRINT_ERROR("invalid id : "<<id<<"\n");
    exit(1);
  }
  
  this->idsOn485Bus[id] = 1;

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
 

/*
  int cntr = 0;  

  //while(1)
  //{
    cntr++;
    ret = this->sd->ReadChars(&c,1,1000);
    if (ret >0)
    {
      printf("."); fflush(stdout);
      ret = DynamixelPacketProcessChar(c,dpacket);
      if (ret >0)
       return ret;
    }

    //if (cntr == 10)
    //  return -1;
  //}
*/ 

  //did not get a full packet yet
  return 0;
}


/////////////////////////////////////////////////////////////////////////
// Process the dynamixel packet coming form the serial bus
/////////////////////////////////////////////////////////////////////////
int MicroGateway::ProcessSerialPacket(DynamixelPacket * dpacket)
{
  int msgId   = DynamixelPacketGetId(dpacket);
  int msgType = DynamixelPacketGetType(dpacket);
  //int ret;
  IpcRawDynamixelPacket ipacket;
  ipacket.t = Upenn::Timer::GetAbsoluteTime();
  ipacket.data = dpacket->buffer;
  ipacket.size = dpacket->lenExpected;

  if (msgId < 0 || msgId > 255)
  {
    PRINT_ERROR("bad msg id " <<msgId<<"\n");
    return -1;
  }

  int idx = this->IdType2Ind(msgId,msgType);
  
  if (idx < 0)
  {
    PRINT_ERROR("calculated message index is bad\n");
    return -1;
  }
  
  
  //publish message via IPC if needed.
  if (this->reggedMsgTypes[idx])
  {
    if (IPC_publishData(this->msgNames[idx].c_str(),&ipacket) != IPC_OK)
    {
      PRINT_ERROR("could not publish packet\n");
      return -1;
    }
  }

  return 0;
}


int MicroGateway::PushRS485Queue(uint8_t id, uint8_t type, uint8_t * buf,
                            uint8_t size)
{
  int outSize;

  //allocate some memory for the packet. this will be freed when it's sent
  uint8_t * tempBuf = new uint8_t[MICRO_GATEWAY_SERIAL_OUTPUT_BUF_SIZE];
  
  //wrap the data into Dynamixel packet
  outSize = DynamixelPacketWrapData(id,type,buf,size,
            tempBuf, MICRO_GATEWAY_SERIAL_OUTPUT_BUF_SIZE);
        
  if (outSize < 0)
    return outSize;
  
  this->PushRS485Queue(tempBuf,outSize,NeedToWaitForRS485Response(id,type), true);
  
  return 0;
}

int MicroGateway::PushRS485Queue(uint8_t * data, int size, bool wait, bool free)
{
  RS485QueueItem qItem;
  qItem.data = data;
  qItem.size = size;
  qItem.wait = wait;
  qItem.free = free;
  
  //push the item into the queue
  this->RS485Queue.push_back(qItem);

  return 0;
}

int MicroGateway::SendRS485Queue()
{
  if (this->RS485Queue.size() == 0)
    return 0;
  
  if (this->waitingRS485Resp && 
      this->rs485timer.Toc() > MICRO_GATEWAY_RS485_RESPONSE_TIMEOUT)
  {
    PRINT_WARNING("timeout!\n");
    this->waitingRS485Resp = false;
  }
    
  if (this->waitingRS485Resp)
    return 0;
    
  
  //get the next item to send
  RS485QueueItem qItem = this->RS485Queue.front();
  
  //remove the item from the queue
  this->RS485Queue.pop_front();
  
  //write data to serial port
  int ret = this->SendSerialPacket(qItem.data,qItem.size);
  
  //free the memory which was allocated upon packet insertion
  if (qItem.free)
    delete [] qItem.data;
  
  if (ret < 0)
  {
    PRINT_ERROR("could not send serial data\n");
    return -1;
  }
  
  //check to see if we need to wait for the response
  if (qItem.wait)
  {
    this->waitingRS485Resp = true;
    rs485timer.Tic();
  }
  
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
    default:
      break;
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

    printf("got gps packet (%f) : ",gpsDt);
    char *c = (char*)DynamixelPacketGetData(dpacket);
    while (*c != '\n')
    {
      printf("%c",*c);
      c++;
    }
    printf("\n");

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
  double motorDt = this->rs485timer.Toc();

  if (packetType == MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE)
  {
    int16_t * encData = (int16_t*)DynamixelPacketGetData(dpacket);
    //printf("got encoder packet (%f) : ",this->encoderTimer.Toc());
    //printf("%d %d %d %d %d\n",(uint16_t)encData[0],encData[1],encData[2],encData[3], encData[4]);

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
    
    int16_t * adcData = (int16_t*)DynamixelPacketGetData(dpacket);
    double imuDt = this->imuTimer.Toc();
    this->imuTimer.Tic();

    /*
    printf("got imu packet (%f) : ",imuDt);        
    for (int ii=0; ii<7; ii++)
      printf("%d ",adcData[ii]);
    printf("\n");
    */
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
/*
    printf("got rot imu packet: %f %f %f %f %f %f\n",
               imu.roll*180/M_PI,imu.pitch*180/M_PI,imu.yaw*180/M_PI,
               imu.wroll*180/M_PI,imu.wpitch*180/M_PI,imu.wyaw*180/M_PI);
*/
  }
  

  else if (packetType == MMC_MAG_RAW)
  {
    int16_t * magData = (int16_t*)DynamixelPacketGetData(dpacket);
    printf("got mag packet : ");
    
    for (int ii=0; ii<4; ii++)
      printf("%d ",magData[ii]);
    printf("\n");

    double magx = magData[1];
    double magy = magData[2];
    double magz = magData[3];

    if (magx > 0 ) magx /= 920.0;
    if (magx < 0 ) magx /= 805.0;
    if (magy > 0 ) magy /= 740.0;
    if (magy < 0 ) magy /= 985.0;
    if (magz > 0 ) magz /= 820.0;
    if (magz < 0 ) magz /= 725.0;

    printf("normalized : %f %f %f\n", magx, magy, magz);
    

    double angle = atan2(magy,magx)/M_PI*180.0+180.0;
    printf("angle = %f, magnitude = %f\n",angle,sqrt(magx*magx + magy*magy + magz*magz));

  }  


  return 0;
}

int MicroGateway::RcPacketHandler(DynamixelPacket * dpacket)
{
  int packetType = DynamixelPacketGetType(dpacket);
  if (packetType == MMC_RC_DECODED)
    {
      uint16_t * data = (uint16_t*)DynamixelPacketGetData(dpacket);
    /*
      printf("got rc packet : ");
      for (int ii=0; ii<7; ii++)
        printf("%d ",data[ii]);
      printf("\n");
    */
    }

  return 0;
}

int MicroGateway::ServoPacketHandler(DynamixelPacket * dpacket)
{
  int id = DynamixelPacketGetId(dpacket);
  if (this->DynamixelControllerUpdate(id,dpacket))
  {
    PRINT_ERROR("error updating dynamixel controller\n");
    return -1;
  }

  return 0;
}

int MicroGateway::DynamixelControllerUpdate(int id, DynamixelPacket * dpacket)
{
  DynamixelController * dcntrl = NULL;  
  DynamixelPacket * packetOut = NULL;  

  int servoIndex = -1;

  switch (id)
  {
    case MMC_DYNAMIXEL0_DEVICE_ID:
      servoIndex = 0;
      dcntrl = this->dynamixelControllers[servoIndex];
      break;
    default:
      break;
  }

  if (dcntrl)
  {
    if (dcntrl->Update(dpacket,&packetOut))
    {
      PRINT_ERROR("error updating dynamixel controller for id "<<id<<"\n");
      return -1;
    }

    //send out packet if needed
    if (packetOut)
    {
      if (this->PushRS485Queue(packetOut->buffer,packetOut->lenReceived,
                          true, false))
      {
        PRINT_ERROR("could not push packet to rs485 queue\n");
        return -1;
      }
    }

    if (dcntrl->FreshAngle())
    {
      double angle = dcntrl->GetAngle();
      //printf("got servo angle %f\n",angle);

      Magic::ServoState sstate;
      sstate.position     = angle/180.0*M_PI;
      sstate.velocity     = 0;
      sstate.acceleration = 0;
      sstate.t            = dcntrl->GetAngleTime();
      sstate.id           = id;
      sstate.counter      = dcntrl->GetAngleCntr();

      if (IPC_publishData(this->dynamixelIpcMsgNames[servoIndex].c_str(),&sstate) != IPC_OK)
      {
        PRINT_ERROR("could not publish dynamixel message to ipc\n");
        return -1;
      }
    }
  }
  else
  {
    PRINT_ERROR("there is no dynamixel controller for id "<<id<<"\n");
  }
  
  return 0;
}

int MicroGateway::ResetImu()
{
  const int bufSize=256;
  uint8_t * tempBuf = new uint8_t[bufSize];

  uint8_t id   = MMC_IMU_DEVICE_ID;
  uint8_t type = MMC_IMU_RESET;

  int len = DynamixelPacketWrapData(id,type,NULL,0,tempBuf,bufSize);
  if (len < 0)
    PRINT_ERROR("could not wrap data\n");

  this->PushRS485Queue(tempBuf,len,false,true);
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
      this->ProcessSerialPacket(&dpacket);
      
      //this->PrintSerialPacket(&dpacket);

      this->HandleSerialPacket(&dpacket);
      
      int deviceId = DynamixelPacketGetId(&dpacket);
      
      //if we received a packet which was on the RS485 bus
      //then we need to clear the flag so that other messages
      //can be sent onto the bus
      if ( this->idsOn485Bus[deviceId] == 1)
        this->waitingRS485Resp = false;
    }


    //request the encoder data if needed
    if (this->encoderTimer.Toc() >= this->encoderUpdateTime)
    //if (0)    
    {
      //printf("sending counter %d\n",cnt);
      if (this->PushRS485Queue(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                         MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST, 
                         (uint8_t *)&encoderCntr, sizeof(uint16_t)) < 0)
      {
        printf("could not send packet");
        return -1;
      }

      this->encoderTimer.Tic();
      encoderCntr++;
    }

    this->DynamixelControllerUpdate(MMC_DYNAMIXEL0_DEVICE_ID,NULL);

    //receive ipc messages
    IPC_listen(0);

    //send the RS485 queue
    this->SendRS485Queue();

    usleep(1000);
  }
}

