#include "DynamixelController.hh"
#include "ErrorMessage.hh"
#include <inttypes.h>

DynamixelController::DynamixelController()
{
  this->mode            = DYNAMIXEL_CONTROLLER_MODE_POINT;
  this->state           = DYNAMIXEL_CONTROLLER_STATE_IDLE;
  this->minAngle        = DYNAMIXEL_CONTROLLER_DEF_MIN_ANGLE;
  this->maxAngle        = DYNAMIXEL_CONTROLLER_DEF_MAX_ANGLE;
  this->desSpeed        = DYNAMIXEL_CONTROLLER_DEF_DES_SPEED;
  this->desAcceleration = DYNAMIXEL_CONTROLLER_DEF_DES_ACCEL;
  this->reversePoint    = DYNAMIXEL_CONTROLLER_DEF_REVERSE_POINT;
  this->desAngle        = 0;
  this->angle           = 0;
  this->freshAngle      = false;
  this->packetOut       = new DynamixelPacket();
  this->dir             = 1;
  this->id              = 0;
  this->angleTime       = 0;
  this->angleCntr       = 0;

  this->cmdTimer.Tic();
  this->feedbackRequestTimer.Tic();
}

DynamixelController::~DynamixelController()
{
  delete this->packetOut;

}

int DynamixelController::SetMinAngle(double angle)
{
  this->minAngle = angle;
  return 0;
}

int DynamixelController::SetMaxAngle(double angle)
{
  this->maxAngle = angle;
  return 0;
}

int DynamixelController::SetSpeed(double speed)
{
  this->desSpeed = speed;
  return 0;
}

int DynamixelController::SetAcceleration(double acceleration)
{
  this->desAcceleration = acceleration;
  return 0;
}

int DynamixelController::SetMode(int mode)
{
  this->mode = mode;
  return 0;
}

double DynamixelController::GetAngle()
{
  this->freshAngle = false;
  return this->angle;
}

int DynamixelController::Update(DynamixelPacket * packetIn, DynamixelPacket ** packetOut)
{
  
  *packetOut = NULL;

  switch (this->state)
  {
    case DYNAMIXEL_CONTROLLER_STATE_IDLE:
      //send the desired position
      this->desAngle = this->dir > 0 ? this->maxAngle : this->minAngle;

      if (this->GenerateAngleCmd(this->desAngle,this->desSpeed,this->packetOut))
      {
        PRINT_ERROR("could not generate position command\n");
        return -1;
      }

      *packetOut = this->packetOut;
      this->state = DYNAMIXEL_CONTROLLER_STATE_SENT_ANGLE_CMD;
      this->cmdTimer.Tic();
      break;

    case DYNAMIXEL_CONTROLLER_STATE_SENT_ANGLE_CMD:
      if (packetIn)
      {
        //verify the angle cmd confirmation
        this->state = DYNAMIXEL_CONTROLLER_STATE_MOVING;
      }
      else if ( cmdTimer.Toc() > DYNAMIXEL_CONTROLLER_ANGLE_CMD_TIMEOUT)
      {
        PRINT_ERROR("angle cmd confirmation timeout!\n");
        this->state = DYNAMIXEL_CONTROLLER_STATE_IDLE;
      }
      break;

    case DYNAMIXEL_CONTROLLER_STATE_MOVING:
      //request the angle feedback if time is up
      if (this->feedbackRequestTimer.Toc() > DYNAMIXEL_CONTROLLER_FEEDBACK_REQUEST_PERIOD)
      {
        if (this->GenerateFeedbackRequestCmd(this->packetOut))
        {
          PRINT_ERROR("could not generate feedback request command\n");
          this->state = DYNAMIXEL_CONTROLLER_STATE_MOVING;
        }
        *packetOut = this->packetOut;
        this->feedbackRequestTimer.Tic();
        this->cmdTimer.Tic();
        this->state = DYNAMIXEL_CONTROLLER_STATE_MOVING_FB_REQUESTED;
      }
      break;

    case DYNAMIXEL_CONTROLLER_STATE_MOVING_FB_REQUESTED:
      if (packetIn)
      {
        //extract the angle
        //check the error code

        if (packetIn->buffer[4] != 0)
        {
          PRINT_ERROR("non-zero error code: " << (int)packetIn->buffer[4] <<"\n");
          return -1;
        }  

        this->AngleVal2AngleDeg(*(uint16_t*)(packetIn->buffer+5),this->angle);
        this->angleTime = Upenn::Timer::GetAbsoluteTime();
        this->angleCntr++;
        this->freshAngle = true;

        //check to see if need to reverse
        if ((this->dir>0) && (this->angle > ( this->desAngle - this->reversePoint)))
        {
          this->state = DYNAMIXEL_CONTROLLER_STATE_IDLE;
          this->dir*=-1;
        }

        else if ((this->dir<0) && (this->angle < (this->desAngle + this->reversePoint)))
        {
          this->state = DYNAMIXEL_CONTROLLER_STATE_IDLE;
          this->dir*=-1;
        }
        else
          this->state = DYNAMIXEL_CONTROLLER_STATE_MOVING;
      }
      else if (this->cmdTimer.Toc() > DYNAMIXEL_CONTROLLER_FB_CMD_TIMEOUT)
      {
        PRINT_ERROR("feedback response timeout!\n");
        this->state = DYNAMIXEL_CONTROLLER_STATE_MOVING;
      }
      break;

    default:
      this->state = DYNAMIXEL_CONTROLLER_STATE_IDLE;
      break;
  }
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert the float angle to uint16 representation
int DynamixelController::AngleDeg2AngleVal(double angle, uint16_t &val)
{
  if ( (angle < DYNAMIXEL_CONTROLLER_MIN_ANGLE ) || 
       (angle > DYNAMIXEL_CONTROLLER_MAX_ANGLE ) )
  {
    PRINT_ERROR("bad angle:"<<angle<<endl);
    return -1;
  }

  val = ((angle-DYNAMIXEL_CONTROLLER_MIN_ANGLE)/
        (DYNAMIXEL_CONTROLLER_MAX_ANGLE-DYNAMIXEL_CONTROLLER_MIN_ANGLE)*1023);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert the uint16 angle to float representation
int DynamixelController::AngleVal2AngleDeg(uint16_t val, double &angle)
{
  angle = val/1023.0*(DYNAMIXEL_CONTROLLER_MAX_ANGLE-DYNAMIXEL_CONTROLLER_MIN_ANGLE) + DYNAMIXEL_CONTROLLER_MIN_ANGLE;
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert double speed to uint16 representation
int DynamixelController::SpeedDeg2SpeedVal(double speed, uint16_t &val)
{
  if ( (speed < 0) || (speed > DYNAMIXEL_AX12_MAX_RPM) )
  {
    PRINT_ERROR("bad speed:"<<speed<<endl);
    return -1;
  }

  val = (speed/DYNAMIXEL_AX12_MAX_VEL*1023);

  //if the value is zero, it means there is no speed limit
  if (val == 0)
    val = 1;

  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Convert uint16 speed to double representation
int DynamixelController::SpeedVal2SpeedDeg(uint16_t val, double &speed)
{
  speed = val/1023.0*DYNAMIXEL_AX12_MAX_VEL;
  return 0;
}

int DynamixelController::GenerateAngleCmd(double angle, double speed, DynamixelPacket * dpacket)
{
  const char cmdLen=5;
  
  //allocated and partially fill in data
  uint8_t cmd[cmdLen] = {DYNAMIXEL_GOAL_POSITION_ADDRESS,0,0,0,0};

  uint16_t pos;
  uint16_t vel;

  if (this->AngleDeg2AngleVal(angle,pos))
  {
    PRINT_ERROR("bad target angle command\n");
    return -1;
  }

  if (this->SpeedDeg2SpeedVal(speed,vel))
  {
    PRINT_ERROR("bad target speed command\n");
    return -1;
  }

  //copy position into the packet
  memcpy(cmd+1,&pos,2);

  //copy velocity into the packet
  memcpy(cmd+3,&vel,2);

  int len = DynamixelPacketWrapData(this->id, DYNAMIXEL_WRITE_DATA_INSTRUCTION,
                                    cmd, cmdLen, 
                                    dpacket->buffer, DYNAMIXEL_PACKET_MAX_SIZE);

  if (len < 1)
  {
    PRINT_ERROR("could not generate angle cmd\n");
    return -1;
  }

  dpacket->lenExpected = dpacket->lenReceived = len;

  return 0;
}


int DynamixelController::GenerateFeedbackRequestCmd(DynamixelPacket * dpacket)
{
  const unsigned int cmdLen = 2;
  uint8_t cmd[cmdLen] = { DYNAMIXEL_PRESENT_POSITION_ADDRESS, 0x02 };

  int len = DynamixelPacketWrapData(this->id, DYNAMIXEL_READ_DATA_INSTRUCTION,
                                    cmd, cmdLen, 
                                    dpacket->buffer, DYNAMIXEL_PACKET_MAX_SIZE);

  if (len < 1)
  {
    PRINT_ERROR("could not generate angle cmd\n");
    return -1;
  }

  dpacket->lenExpected = dpacket->lenReceived = len;

  return 0;
}

int DynamixelController::SetId(int id)
{
  if (id < 0 || id > 255)
  {
    PRINT_ERROR("bad id: " <<id<<"\n");
    return -1;
  }
  
  this->id = id;
  return 0;
}
