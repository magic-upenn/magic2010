//Driver for Dynamixel AX-12 (and others) servo module
//
//Aleksandr Kushleyev
//University of Pennsylvania
//August 2009 
//akushley@seas.upenn.edu

#include "Dynamixel.hh"
#include <time.h>
#include <math.h>
#include "ErrorMessage.hh"

//#define DYNAMIXEL_DEBUG

////////////////////////////////////////////////////////////////////////////////
// Constructor
Dynamixel::Dynamixel()
{
  this->sd                = NULL;
  this->connected         = false;
  this->moduleId          = DYNAMIXEL_DEFAULT_MODULE_ID;
  this->lastDeviceError   = 0;
  this->lastDriverError   = 0;
  this->lastAngleTime     = 0;
  this->inBuffer          = new char[DYNAMIXEL_DEF_BUFFER_LENGTH];
  this->outBuffer         = new char[DYNAMIXEL_DEF_BUFFER_LENGTH];
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
Dynamixel::~Dynamixel()
{
  if (this->sd) delete this->sd;
  delete [] this->inBuffer;
  delete [] this->outBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// Connect to the servo. Each should have a unique module id
int Dynamixel::Connect(string device, int baudRate, int moduleId)
{
  if (this->connected)
    return 0;

  if (moduleId < 0)
  {
    PRINT_ERROR("module ID must be non-negative \n");
    return -1;
  }

  //create instance of serial device 
  this->sd = new SerialDevice();

  if (!this->sd)
  {
    PRINT_ERROR("could not create instance of SerialDevice\n");
    return -1;
  }

  //connecto to serial device
  if (this->sd->Connect(device.c_str(),baudRate))
  {
    PRINT_ERROR("could not connect to the device \n");
    return -1;
  }

  this->moduleId = moduleId;

  this->connected = true;
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Disconnect from the servo
int Dynamixel::Disconnect()
{
  if (this->connected)
  {
    this->sd->Disconnect();
  }
  this->connected = false;
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Calculate the checksum (from Dynamixel manual)
// packet format (from Dynamixel manual:
// http://www.crustcrawler.com/motors/RX28/docs/RX28_Manual.pdf )
// [OxFF][0xFF][ID][LENGTH][INSTRUCTION][PARAMETER1]..[PARAMETERN][CHECKSUM]
// CHECKSUM = ~ ( ID + Length + Instruction + Parameter1 + ... Parameter N )
unsigned char Dynamixel::CalcCheckSum(unsigned char * buf, bool writeToBuf)
{
  unsigned char length   = buf[3];
  unsigned char sum      = buf[2] + buf[3];  //id + length
  unsigned char * ptr    = buf + 4;  
  unsigned char lenCheck = length - 1;

  for (unsigned int ii=0; ii<lenCheck; ii++)
    sum += *ptr++;

  sum  = ~sum;

  if (writeToBuf)
    *ptr = sum;
  
  return sum;
}

////////////////////////////////////////////////////////////////////////////////
// pack up the data for shipping out to the device (adds header, length, checksum)
int Dynamixel::CreateOutgoingPacket(void * payload, unsigned int length, 
                                       char * packet, unsigned int maxLength)
{

  //error checking
  if ( (length == 0) || (length > 255))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("bad payload length: "<<length<<endl);
#endif
    return -1;
  }

  if (maxLength < length + 5)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("ERROR: Trying to create a packet with not enough allocated memory"<<endl);
#endif
    return -1;
  }

  //header
  packet[0] = 0xFF; //first two bytes are 0xFF
  packet[1] = 0xFF;
  packet[2] = this->moduleId;
  packet[3] = (unsigned char)length+1;  //including the checksum
  
  //copy payload
  memcpy( (packet + DYNAMIXEL_PACKET_HEADER_LENGTH), payload, length );

  //calculate the checksum
  this->CalcCheckSum((unsigned char *)packet);

  int packetLength = length + 5;

#ifdef DYNAMIXEL_DEBUG
  PRINT_INFO("Sending Packet:");
  this->PrintPacket(packet,packetLength);
#endif

  return packetLength;
}

////////////////////////////////////////////////////////////////////////////////
// Read a packet and verify the checksum
int Dynamixel::ReadPacket(char * packet, unsigned int maxLength, unsigned int timeoutUs)
{
  if (!this->connected)
  {
    PRINT_ERROR("not connected!\n");
    return -1;
  }
  
  //read the header
  unsigned int n = this->sd->ReadChars(packet,4,timeoutUs);

  if (n!=4)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not read packet header"<<endl);
#endif
    this->lastDriverError = DYNAMIXEL_ERROR_TIMEOUT;
    return -1;
  }

  //read the reset of the message based on the size
  unsigned int nRem = (unsigned int)(((unsigned char *)packet)[3]);

  //check to make sure that enough memory is allocated
  if (maxLength < nRem+4)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("not enough space allocated for the packet"<<endl);
#endif
    this->lastDriverError = DYNAMIXEL_ERROR_NOT_ENOUGH_SPACE;
    return -1;
  }

  n = this->sd->ReadChars(packet+4, nRem, timeoutUs);

  if (n!=nRem)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not read second part of the packet"<<endl);
#endif
    this->lastDriverError = DYNAMIXEL_ERROR_INCOMPLETE_PACKET;
    return -1;
  }

  unsigned char crcExpected = *(unsigned char*)(packet+n+3);
  unsigned char crcActual   = this->CalcCheckSum((unsigned char*)packet,false);

  if (crcActual != crcExpected)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("Dynamixel::ReadPacket: ERROR: crc mismatch. Packet length="<<n+4<<endl);
    PRINT_ERROR("Actual: "<<crcActual<<", Expected: "<<crcExpected<<endl);
    this->PrintPacket(packet,n+4);
#endif
    this->lastDriverError = DYNAMIXEL_ERROR_BAD_CHECKSUM;
    return -1;
  }
  
  return n+4;
}

////////////////////////////////////////////////////////////////////////////////
// Write packet to the device
int Dynamixel::WritePacket(char * packet, unsigned int length)
{
  if (!this->connected)
  {
    PRINT_ERROR("not connected!\n");
    return -1;
  }

  if ((unsigned int)this->sd->WriteChars(packet,length) != length)
  {
    PRINT_ERROR("not write chars!\n");
    return -1;
  }

  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Print out the packet to the terminal
void Dynamixel::PrintPacket(char * buf, int length)
{
  cout.setf(ios::hex,ios::basefield);
  cout.setf(ios::showbase);

  for (int ii=0; ii<length; ii++)
    PRINT_INFO_RAW((unsigned char)buf[ii]<<" ");
  PRINT_INFO_RAW("\n");
  
  resetiosflags (ios_base::basefield);
  resetiosflags (ios_base::showbase);
}


////////////////////////////////////////////////////////////////////////////////
// Request and get the position feedback
int Dynamixel::GetPosition(float & position)
{
  const unsigned int cmdLen = 3;
  unsigned char cmd[cmdLen] = { DYNAMIXEL_READ_DATA_INSTRUCTION,
                                DYNAMIXEL_PRESENT_POSITION_ADDRESS,
                                0x02 };

  int packetLength = this->CreateOutgoingPacket(cmd, cmdLen, this->outBuffer,DYNAMIXEL_DEF_BUFFER_LENGTH);

  if (this->WritePacket(this->outBuffer,packetLength))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not write packet"<<endl);
#endif
    return -1;
  }

  packetLength = this->ReadPacket(this->inBuffer,DYNAMIXEL_DEF_BUFFER_LENGTH);

  //check the error code
  if (this->inBuffer[4] != 0)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("non-zero error code: " (int)this->inBuffer[4] << <<endl);
#endif
    return -1;
  }  

  this->AngleVal2AngleDeg(*(uint16_t*)(this->inBuffer+5),position);
  this->lastAngleTime = Timer::GetAbsoluteTime();//this->sd->GetLastInputPacketTime();
#ifdef DYNAMIXEL_DEBUG
  PRINT_INFO("Current Position: "<<position<<endl);
#endif

  return 0;
}


////////////////////////////////////////////////////////////////////////////////
// stop the unit : send the command and wait for the request
int Dynamixel::StopUnit()
{
  //TODO
  return 0;
}


////////////////////////////////////////////////////////////////////////////////
// send stop command
int Dynamixel::SendStopCmd()
{
  //TODO
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert the float angle to uint16 representation
int Dynamixel::AngleDeg2AngleVal(float angle, uint16_t &val)
{
  if ( (angle < DYNAMIXEL_MIN_ANGLE ) || (angle > DYNAMIXEL_MAX_ANGLE ) )
  {
    PRINT_ERROR("bad angle:"<<angle<<endl);
    return -1;
  }

  val = ((angle-DYNAMIXEL_MIN_ANGLE)/(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE)*1023);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert the uint16 angle to float representation
int Dynamixel::AngleVal2AngleDeg(uint16_t val, float &angle)
{
  angle = val/1023.0*(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE) + DYNAMIXEL_MIN_ANGLE;
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert float velocity to uint16 representation
int Dynamixel::VelocityDeg2VelocityVal(float velocity, uint16_t &val)
{
  if ( (velocity < 0) || (velocity > DYNAMIXEL_AX12_MAX_RPM) )
  {
    PRINT_ERROR("bad velocity:"<<velocity<<endl);
    return -1;
  }

  val = (velocity/DYNAMIXEL_AX12_MAX_VEL*1023);

  //if the value is zero, it means there is no velocity limit
  if (val == 0)
    val = 1;

  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert uint16 velocity to float representation
int Dynamixel::VelocityVal2VelocityDeg(uint16_t val, float &velocity)
{
  velocity = val/1023.0*DYNAMIXEL_AX12_MAX_VEL;
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Send a command to request motion to a position using provided velocity 
// and stored acceleration
int Dynamixel::MoveToPos(float position, float velocity)
{
  const char cmdLength=6;
  
  //allocated and partially fill in data
  char cmd[cmdLength] = { DYNAMIXEL_WRITE_DATA_INSTRUCTION,
                          DYNAMIXEL_GOAL_POSITION_ADDRESS,
                          0,0,0,0};

  uint16_t pos;
  uint16_t vel;

  if (this->AngleDeg2AngleVal(position,pos))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("bad target angle command"<<endl);
#endif
    return -1;
  }

  if (this->VelocityDeg2VelocityVal(velocity,vel))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("bad target velocity command"<<endl);
#endif
    return -1;
  }

  //copy position into the packet
  memcpy(cmd+2,&pos,2);

  //copy velocity into the packet
  memcpy(cmd+4,&vel,2);

  //pack the outgoing packet
  int packetLength = this->CreateOutgoingPacket(cmd, cmdLength, this->outBuffer,DYNAMIXEL_DEF_BUFFER_LENGTH);

  if (packetLength < 0)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not create packet"<<endl);
#endif
    return -1;
  }

  if (this->WritePacket(outBuffer,packetLength))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not write packet"<<endl);
#endif
    return -1;
  }

  uint16_t status;
  if (this->GetCmdConfirmation(status))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not get command confirmation"<<endl);
#endif
    return -1;
  }
  
  return 0;
}


////////////////////////////////////////////////////////////////////////////////
// make sure that the command has been received
int Dynamixel::GetCmdConfirmation(uint16_t &status)
{
  int packetLength = this->ReadPacket(this->inBuffer,DYNAMIXEL_DEF_BUFFER_LENGTH,100000);

  if (packetLength < 1)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not read packet"<<endl);
#endif
    return -1;
  }

  status = *(unsigned char*)(this->inBuffer+4);
  
  if (status == DYNAMIXEL_RESPONSE_NO_ERROR)
    return 0;
  else
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("error occured"<<status<<endl);
    this->PrintPacket(inputBuffer,packetLength);
#endif
    return -1;
  }

}

////////////////////////////////////////////////////////////////////////////////
// handle an unexpected message
int Dynamixel::HandleOtherMessage(char * packet, unsigned int packetLength)
{
#ifdef DYNAMIXEL_DEBUG
  PRINT_ERROR("Received unexpected message"<<endl);
  this->PrintPacket(packet,packetLength);
#endif
  return 0;
}


////////////////////////////////////////////////////////////////////////////////
// get the device information (model number)
int Dynamixel::GetDeviceInfo(string & info)
{
  const unsigned int cmdLen = 3;
  unsigned char cmd[cmdLen] = { DYNAMIXEL_READ_DATA_INSTRUCTION,
                                DYNAMIXEL_MODEL_NUMBER_ADDRESS,
                                0x02 };
  int packetLength = this->CreateOutgoingPacket(cmd, cmdLen, this->outBuffer, DYNAMIXEL_DEF_BUFFER_LENGTH);

  if (packetLength < 0)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not create packet"<<endl);
#endif
    return -1;
  }

  if (this->WritePacket(this->outBuffer,packetLength))
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not write packet"<<endl);
#endif
    return -1;
  }

  packetLength = this->ReadPacket(this->inBuffer,DYNAMIXEL_DEF_BUFFER_LENGTH,1000000);
  if (packetLength < 1)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not read packet"<<endl);
#endif
    return -1;
  }

/*
  //check to see if the response type matches the request
  if ( this->GetCmdType(inputBuffer) != cmd)
  {
    this->HandleOtherMessage(inputBuffer,packetLength);
    return -1;
  }
*/
#ifdef DYNAMIXEL_DEBUG  
  this->PrintPacket(this->inBuffer,packetLength);
  PRINT_INFO(("Device Information: "<<*(unsigned char*)(inputBuffer+5)<<endl);
#endif
  info = string(this->inBuffer+5);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// get the last stored error code that came from device
unsigned char Dynamixel::GetLastDeviceError()
{
  unsigned char error = this->lastDeviceError;
  this->lastDeviceError = 0;
  return error;
}

////////////////////////////////////////////////////////////////////////////////
// get the last stored error code, set by this driver
unsigned char Dynamixel::GetLastDriverError()
{
  unsigned char error = this->lastDriverError;
  this->lastDriverError = 0;
  return error;
}

////////////////////////////////////////////////////////////////////////////////
// Execute device initialization here
int Dynamixel::StartDevice()
{
  string devInfo;

  //set io mode. See SerialDevice.hh for more detail on io modes
	if (this->sd->Set_IO_BLOCK_W_TIMEOUT())
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("Could not set IO mode"<<endl);
#endif
    return -1;
  }

  bool sensorAlive = false;  

  for (int ii=0; ii<DYNAMIXEL_STARTUP_RETRIES; ii++)
  {

    //make sure there is nothing in the serial buffer
    this->sd->FlushInputBuffer();

    //read the device name (this wakes up the unit)
    if (this->GetDeviceInfo(devInfo) )
    {
      //if the query failed it can be either due to a timeout or an error code returned
      if (this->GetLastDriverError() == DYNAMIXEL_ERROR_TIMEOUT)
      {
#ifdef DYNAMIXEL_DEBUG
        PRINT_ERROR("could not get device info"<<endl);
#endif
        continue;
      }
      //if we got an error code, then the device is alive (sometimes unit responds with an error code
      //to the first request)
      else if (this->GetLastDeviceError() != 0)
      {
#ifdef DYNAMIXEL_DEBUG
        PRINT_ERROR("status query returned an error"<<endl);
#endif
      }
    }
   
    else
    {
      sensorAlive = true;
      break;
    }
  }

  if (!sensorAlive)
  {
#ifdef DYNAMIXEL_DEBUG
    PRINT_ERROR("could not establish communication with the sensor"<<endl);
#endif
    return -1;
  }

  return 0;
}


////////////////////////////////////////////////////////////////////////////////
// Stop the device
int Dynamixel::StopDevice()
{
  this->sd->FlushInputBuffer();

  for (int ii=0; ii<DYNAMIXEL_STOP_UNIT_RETRIES; ii++)
  {
    if (this->StopUnit() == 0)
      return 0;

    usleep(50000);
  }

#ifdef DYNAMIXEL_DEBUG
  PRINT_ERROR("could not stop the device"<<endl);
#endif
  return -1;
}

////////////////////////////////////////////////////////////////////////////////
// Get the timestamp of the last feedback angle
double Dynamixel::GetLastAngleTime()
{
  return this->lastAngleTime;
}



