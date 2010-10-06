#include "Servo1Controller.h"
#include "config.h"
#include <string.h>

float    _servo1SpeedF;
float    _servo1MinAngleF;
float    _servo1MaxAngleF;
uint8_t  _servo1State;
uint8_t  _servo1Mode;
uint32_t _servo1Time;
uint32_t _servo1AngleTime;
float    _servo1AngleF;
float    _servo1DesAngleF;
uint16_t _servo1AngleI;
uint8_t  _servo1FreshAngle;
uint8_t  _servo1AngleCntr;
int8_t   _servo1Dir;
float    _servo1ReversePt;
uint32_t _servo1ReqTime;
uint32_t _servo1ReqTimeout;
uint32_t _servo1NextReqTime;

uint8_t  _servo1ConfigChanged = 0;
float    _servo1TempMinAngleF;
float    _servo1TempMaxAngleF;
float    _servo1TempSpeedF;
uint8_t  _servo1TempMode;


//                             -HEADER--,-------ID-----------,LEN-,CMD-,ADDR,SIZE,SUM
uint8_t _servo1FbReqPacket[]  = {0xFF,0xFF,UAV_DEVICE_ID_SERVO1,0x04,0x02,0x24,0x02,0x00};
const uint8_t _servo1FbReqPacketSize = 8;


//default to 512 angle (center) and 512 speed.
uint8_t _servo1SetMinPacket[] = {0xFF,0xFF,UAV_DEVICE_ID_SERVO1,0x07,0x03,0x1E,
                                 0x00,0x02,0x00,0x02, 0x00};
uint8_t _servo1SetMaxPacket[] = {0xFF,0xFF,UAV_DEVICE_ID_SERVO1,0x07,0x03,0x1E,
                                 0x00,0x02,0x00,0x02, 0x00};

void Servo1UpdateConfig()
{
  if (!_servo1ConfigChanged)
    return;

  _servo1Mode      = _servo1TempMode;
  _servo1SpeedF    = _servo1TempSpeedF;

  _servo1MinAngleF = _servo1TempMinAngleF;
  Servo1FillAnglePacket(_servo1MinAngleF,_servo1SpeedF,_servo1SetMinPacket);

  _servo1MaxAngleF = _servo1TempMaxAngleF;
  Servo1FillAnglePacket(_servo1MaxAngleF,_servo1SpeedF,_servo1SetMaxPacket);


  _servo1State     = SERVO_CONTROLLER_STATE_IDLE;
  _servo1ConfigChanged = 0;
}

inline void Servo1UpdateTime(uint32_t timeMs)
{
  _servo1Time = timeMs;
}

inline void Servo1SetMode(uint8_t mode)
{
  _servo1TempMode = mode;
  _servo1ConfigChanged = 1;
}

void Servo1ComputeAndSetChecksum(uint8_t * packet)
{
  uint8_t len      = packet[3];
  uint8_t sum      = packet[2] + packet[3];
  uint8_t * ptr    = packet + 4;
  uint8_t lenCheck = len -1;
  uint8_t ii;

  for (ii=0; ii<lenCheck; ii++)
    sum += *ptr++;

  sum = ~sum;
  *ptr = sum;
}

void Servo1FillAnglePacket(float angle, float speed, uint8_t * packet)
{
  //convert float angle to uint16
  uint16_t a;
  uint16_t s;

  //error checking
  if ( (angle < DYNAMIXEL_MIN_ANGLE ) || (angle > DYNAMIXEL_MAX_ANGLE ) )
    angle = 0.0;

  if ( (speed < 0) || (speed > DYNAMIXEL_AX12_MAX_SPEED) )
    speed = DYNAMIXEL_AX12_MAX_SPEED*0.5;

  a = ((angle-DYNAMIXEL_MIN_ANGLE)/(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE)*1023.0);
  s = (speed/DYNAMIXEL_AX12_MAX_SPEED*1023.0);
  
  //write the values into the packet
  memcpy(packet+6,&a,sizeof(uint16_t));
  memcpy(packet+8,&s,sizeof(uint16_t));

  //compute checksum
  Servo1ComputeAndSetChecksum(packet);
}

void Servo1SetMinAngle(float angle)
{
  _servo1TempMinAngleF = angle;
  _servo1ConfigChanged = 1;
}

void Servo1SetMaxAngle(float angle)
{
  _servo1TempMaxAngleF = angle;
  _servo1ConfigChanged = 1;
}

void Servo1SetSpeed(float speed)
{
  _servo1TempSpeedF = speed;
  _servo1ConfigChanged = 1;
}
  
  
int Servo1Init(uint32_t initTime)
{
  _servo1SpeedF     = SERVO1_DEF_SPEED;
  _servo1MinAngleF  = SERVO1_DEF_MIN_ANGLE;
  _servo1MaxAngleF  = SERVO1_DEF_MAX_ANGLE;
  _servo1State      = SERVO1_DEF_STATE;
  _servo1FreshAngle = 0;
  _servo1AngleCntr  = 0;
  _servo1Mode       = SERVO_CONTROLLER_MODE_IDLE;
  _servo1Dir        = 1;
  _servo1AngleF     = 0;
  _servo1DesAngleF  = 0;
  _servo1ReversePt  = SERVO1_DEF_REVERSE_POINT;
  _servo1NextReqTime= initTime;

  Servo1ComputeAndSetChecksum(_servo1FbReqPacket);
  Servo1FillAnglePacket(_servo1MinAngleF,_servo1SpeedF,_servo1SetMinPacket);
  Servo1FillAnglePacket(_servo1MaxAngleF,_servo1SpeedF,_servo1SetMaxPacket);

  return 0;
}

float Servo1GetAngle()
{
  _servo1FreshAngle = 0;
  return _servo1AngleF;
}

uint8_t Servo1IsFreshAngle()
{
  return _servo1FreshAngle;
}

uint32_t Servo1GetAngleTime()
{
  return _servo1AngleTime;
}

uint8_t Servo1GetAngleCntr()
{
  return _servo1AngleCntr;
}

int Servo1Update(DynamixelPacket * packetIn, uint8_t ** packetOut, uint8_t * sizeOut)
{
  *packetOut = NULL;
  *sizeOut   = 0;
  

  if (_servo1Mode == SERVO_CONTROLLER_MODE_IDLE)
    return 0;

  else if (_servo1Mode == SERVO_CONTROLLER_MODE_FB_ONLY)
  {
    switch (_servo1State)
    {
      case SERVO_CONTROLLER_STATE_UNINITIALIZED:
      case SERVO_CONTROLLER_STATE_IDLE:
        if (_servo1Time < _servo1NextReqTime)
          break;

        //only update the configuration when it's safe
        if (_servo1ConfigChanged)
        {
          Servo1UpdateConfig();
          break;
        }

        //send out the request command
        *packetOut          = _servo1FbReqPacket;
        *sizeOut            = _servo1FbReqPacketSize;
        _servo1State        = SERVO_CONTROLLER_STATE_FB_REQUESTED;
        _servo1ReqTime      = _servo1Time;
        _servo1ReqTimeout   = _servo1Time + SERVO1_REQ_TIMEOUT_DELTA;
        _servo1NextReqTime  = _servo1ReqTime + SERVO1_NEXT_REQ_DELTA;
        break;

      case SERVO_CONTROLLER_STATE_FB_REQUESTED:
        if (packetIn)
        {
          if ((packetIn->buffer[4] != 0) || (DynamixelPacketGetPayloadSize(packetIn) != 2))
            break;
          _servo1AngleI       = *(uint16_t*)(packetIn->buffer+5);
          _servo1AngleTime    = _servo1Time;
          _servo1FreshAngle   = 1;
          _servo1State        = SERVO_CONTROLLER_STATE_IDLE;
          _servo1AngleF       = _servo1AngleI/1023.0*(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE) +
                                 DYNAMIXEL_MIN_ANGLE;
        }
        else if (_servo1Time > _servo1ReqTimeout)
          _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        break;
        
      default:
        break;
    }
  }

  else if (_servo1Mode == SERVO_CONTROLLER_MODE_POINT)
  {
    switch (_servo1State)
    {
      case SERVO_CONTROLLER_STATE_UNINITIALIZED:
      case SERVO_CONTROLLER_STATE_IDLE:
        if (_servo1Time < _servo1NextReqTime)
          break;

        //only update the configuration when it's safe
        if (_servo1ConfigChanged)
        {
          Servo1UpdateConfig();
          break;
        }

        *packetOut       = _servo1SetMinPacket;
        _servo1DesAngleF = _servo1MinAngleF;
          
        *sizeOut          = 11;
        _servo1State      = SERVO_CONTROLLER_STATE_SENT_ANGLE_CMD;
        _servo1ReqTime    = _servo1Time;
        _servo1ReqTimeout = _servo1Time + SERVO1_REQ_TIMEOUT_DELTA;
        _servo1NextReqTime = _servo1ReqTime + SERVO1_NEXT_REQ_DELTA;
        break;

      case SERVO_CONTROLLER_STATE_SENT_ANGLE_CMD:
        if (packetIn)
        {
          if (packetIn->buffer[4] == 0 && (DynamixelPacketGetPayloadSize(packetIn) == 0))
            _servo1State = SERVO_CONTROLLER_STATE_MOVING;
          else
            _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        }
        else if (_servo1Time > _servo1ReqTimeout)
          _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        break;

      case SERVO_CONTROLLER_STATE_MOVING:
        if (_servo1Time < _servo1NextReqTime)
          break;

        //only update the configuration when it's safe
        if (_servo1ConfigChanged)
        {
          Servo1UpdateConfig();
          break;
        }

        *packetOut        = _servo1FbReqPacket;
        *sizeOut          = _servo1FbReqPacketSize;
        _servo1State      = SERVO_CONTROLLER_STATE_MOVING_FB_REQUESTED;
        _servo1ReqTime    = _servo1Time;
        _servo1ReqTimeout = _servo1Time + SERVO1_REQ_TIMEOUT_DELTA;
        _servo1NextReqTime = _servo1ReqTime + SERVO1_NEXT_REQ_DELTA;
        break;

      case SERVO_CONTROLLER_STATE_MOVING_FB_REQUESTED:
        if (packetIn)
        {
          if ((packetIn->buffer[4] != 0) || (DynamixelPacketGetPayloadSize(packetIn) != 2))
            break;

          _servo1AngleI       = *(uint16_t*)(packetIn->buffer+5);
          _servo1AngleTime    = _servo1Time;
          _servo1FreshAngle   = 1;
          _servo1AngleF       = _servo1AngleI/1023.0*(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE) +
                                 DYNAMIXEL_MIN_ANGLE;

          _servo1State = SERVO_CONTROLLER_STATE_MOVING;
          
        }
        else if (_servo1Time > _servo1ReqTimeout)
          _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        break;
    }
  }

  else if (_servo1Mode == SERVO_CONTROLLER_MODE_SERVO)
  {
    switch (_servo1State)
    {
      case SERVO_CONTROLLER_STATE_UNINITIALIZED:
      case SERVO_CONTROLLER_STATE_IDLE:
        if (_servo1Time < _servo1NextReqTime)
          break;

        //only update the configuration when it's safe
        if (_servo1ConfigChanged)
        {
          Servo1UpdateConfig();
          break;
        }

        if (_servo1Dir > 0)
        {
          *packetOut       = _servo1SetMaxPacket;
          _servo1DesAngleF = _servo1MaxAngleF;
        }
        else
        {
          *packetOut       = _servo1SetMinPacket;
          _servo1DesAngleF = _servo1MinAngleF;
        }
          
        *sizeOut          = 11;
        _servo1State      = SERVO_CONTROLLER_STATE_SENT_ANGLE_CMD;
        _servo1ReqTime    = _servo1Time;
        _servo1ReqTimeout = _servo1Time + SERVO1_REQ_TIMEOUT_DELTA;
        _servo1NextReqTime = _servo1ReqTime + SERVO1_NEXT_REQ_DELTA;
        break;

      case SERVO_CONTROLLER_STATE_SENT_ANGLE_CMD:
        if (packetIn)
        {
          if (packetIn->buffer[4] == 0 && (DynamixelPacketGetPayloadSize(packetIn) == 0))
            _servo1State = SERVO_CONTROLLER_STATE_MOVING;
          else
            _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        }
        else if (_servo1Time > _servo1ReqTimeout)
          _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        break;

      case SERVO_CONTROLLER_STATE_MOVING:
        if (_servo1Time < _servo1NextReqTime)
          break;

        //only update the configuration when it's safe
        if (_servo1ConfigChanged)
        {
          Servo1UpdateConfig();
          break;
        }

        *packetOut        = _servo1FbReqPacket;
        *sizeOut          = _servo1FbReqPacketSize;
        _servo1State      = SERVO_CONTROLLER_STATE_MOVING_FB_REQUESTED;
        _servo1ReqTime    = _servo1Time;
        _servo1ReqTimeout = _servo1Time + SERVO1_REQ_TIMEOUT_DELTA;
        _servo1NextReqTime = _servo1ReqTime + SERVO1_NEXT_REQ_DELTA;
        break;

      case SERVO_CONTROLLER_STATE_MOVING_FB_REQUESTED:
        if (packetIn)
        {
          if ((packetIn->buffer[4] != 0) || (DynamixelPacketGetPayloadSize(packetIn) != 2))
            break;

          _servo1AngleI       = *(uint16_t*)(packetIn->buffer+5);
          _servo1AngleTime    = _servo1Time;
          _servo1FreshAngle   = 1;
          _servo1AngleF       = _servo1AngleI/1023.0*(DYNAMIXEL_MAX_ANGLE-DYNAMIXEL_MIN_ANGLE) +
                                 DYNAMIXEL_MIN_ANGLE;

          if ( (_servo1Dir > 0) && (_servo1AngleF > (_servo1DesAngleF - _servo1ReversePt)) )
          {
            _servo1State = SERVO_CONTROLLER_STATE_IDLE;
            _servo1Dir  *= -1;
          }
          else if ( (_servo1Dir < 0) && (_servo1AngleF < (_servo1DesAngleF + _servo1ReversePt)) )
          {
            _servo1State = SERVO_CONTROLLER_STATE_IDLE;
            _servo1Dir  *= -1;
          }
          else
            _servo1State = SERVO_CONTROLLER_STATE_MOVING;
          
        }
        else if (_servo1Time > _servo1ReqTimeout)
          _servo1State = SERVO_CONTROLLER_STATE_IDLE;
        break;
    }
  }

  
  return 0;
}







