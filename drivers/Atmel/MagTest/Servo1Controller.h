#ifndef SERVO1_CONTROLLER_H
#define SERVO1_CONTROLLER_H

#include <stdint.h>
#include "DynamixelPacket.h"
#include "MagicMicroCom.h"


#define SERVO1_DEF_MIN_ANGLE -20
#define SERVO1_DEF_MAX_ANGLE  20
#define SERVO1_DEF_SPEED      50
#define SERVO1_DEF_STATE      SERVO_CONTROLLER_STATE_IDLE

#define DYNAMIXEL_MIN_ANGLE                -150
#define DYNAMIXEL_MAX_ANGLE                 150
#define DYNAMIXEL_AX12_MAX_RPM              114
#define DYNAMIXEL_AX12_MAX_SPEED            (DYNAMIXEL_AX12_MAX_RPM/60.0*360.0)
#define SERVO1_DEF_REVERSE_POINT 2
#define SERVO1_REQ_TIMEOUT_DELTA              250
#define SERVO1_NEXT_REQ_DELTA               1500

#define UAV_DEVICE_ID_SERVO1 4

  //states for the built-in mini-state machine
enum { SERVO_CONTROLLER_STATE_UNINITIALIZED, 
       SERVO_CONTROLLER_STATE_IDLE,
       SERVO_CONTROLLER_STATE_FB_REQUESTED,
       SERVO_CONTROLLER_STATE_SENT_ANGLE_CMD,
       SERVO_CONTROLLER_STATE_MOVING,
       SERVO_CONTROLLER_STATE_MOVING_FB_REQUESTED
     };

enum { SERVO_CONTROLLER_MODE_IDLE,
       SERVO_CONTROLLER_MODE_FB_ONLY,
       SERVO_CONTROLLER_MODE_POINT,
       SERVO_CONTROLLER_MODE_SERVO
     };


int       Servo1Init(uint32_t initTime);
void      Servo1UpdateTime(uint32_t timeMs);
void      Servo1SetMode(uint8_t mode);
void      Servo1SetMinAngle(float angle);
void      Servo1SetMaxAngle(float angle);
void      Servo1SetSpeed(float speed);
int       Servo1Update(DynamixelPacket * packetIn, uint8_t ** packetOut, uint8_t * sizeOut);
float     Servo1GetAngle();
uint8_t   Servo1IsFreshAngle();
uint32_t  Servo1GetAngleTime();
void Servo1ComputeAndSetChecksum(uint8_t * packet);
void Servo1FillAnglePacket(float angle, float speed, uint8_t * packet);

uint8_t Servo1GetAngleCntr();


#endif //SERVO1_CONTROLLER_H
