#ifndef DYNAMIXEL_CONTROLLER_HH
#define DYNAMIXEL_CONTROLLER_HH

#include "DynamixelPacket.h"
#include "Timer.hh"

#define DYNAMIXEL_CONTROLLER_DEF_MIN_ANGLE          -0
#define DYNAMIXEL_CONTROLLER_DEF_MAX_ANGLE           0
#define DYNAMIXEL_CONTROLLER_DEF_DES_SPEED           50
#define DYNAMIXEL_CONTROLLER_DEF_DES_ACCEL           300
#define DYNAMIXEL_CONTROLLER_DEF_REVERSE_POINT       5
#define DYNAMIXEL_CONTROLLER_ANGLE_CMD_TIMEOUT       0.050
#define DYNAMIXEL_CONTROLLER_FEEDBACK_REQUEST_PERIOD 0.020
#define DYNAMIXEL_CONTROLLER_FB_CMD_TIMEOUT          0.050
#define DYNAMIXEL_AX12_MAX_RPM                       114
#define DYNAMIXEL_CONTROLLER_MIN_ANGLE              -150
#define DYNAMIXEL_CONTROLLER_MAX_ANGLE               150



#define DYNAMIXEL_READ_DATA_INSTRUCTION              0x02
#define DYNAMIXEL_WRITE_DATA_INSTRUCTION             0x03

#define DYNAMIXEL_MODEL_NUMBER_ADDRESS               0x00
#define DYNAMIXEL_PRESENT_POSITION_ADDRESS           0x24
#define DYNAMIXEL_GOAL_POSITION_ADDRESS              0x1E

#define DYNAMIXEL_AX12_MAX_VEL                       (DYNAMIXEL_AX12_MAX_RPM/60.0*360.0)

  //states for the built-in mini-state machine
enum { DYNAMIXEL_CONTROLLER_STATE_UNINITIALIZED, 
       DYNAMIXEL_CONTROLLER_STATE_IDLE,
       DYNAMIXEL_CONTROLLER_STATE_SENT_ANGLE_CMD,
       DYNAMIXEL_CONTROLLER_STATE_MOVING,
       DYNAMIXEL_CONTROLLER_STATE_MOVING_FB_REQUESTED
     };

enum { DYNAMIXEL_CONTROLLER_MODE_POINT,
       DYNAMIXEL_CONTROLLER_MODE_SERVO
     };

#define DYNAMIXEL_CONTROLLER_DEF_MODE DYNAMIXEL_CONTROLLER_MODE_POINT

class DynamixelController
{


  public: DynamixelController();
  public: ~DynamixelController();
  public: int SetMinAngle(double angle);
  public: int SetMaxAngle(double angle);
  public: int SetSpeed(double speed);
  public: int SetAcceleration(double acceleration);
  public: int Update(DynamixelPacket * packetIn, DynamixelPacket ** packetOut);
  public: inline bool FreshAngle() {return this->freshAngle;}
  public: double GetAngle();
  public: inline double GetAngleTime() {return this->angleTime;}
  public: inline unsigned int GetAngleCntr() {return this->angleCntr;}
  public: int SetMode(int mode);
  public: int SetId(int id);
  public: int SetMinLimit(double angle);
  public: int SetMaxLimit(double angle);
  public: int ResetState();  

  //convert angle in degrees to position command
  private: int AngleDeg2AngleVal(double angle, uint16_t &val);

  //convert the position feedback to degrees
  private: int AngleVal2AngleDeg(uint16_t val, double &angle);

  //convert speed in degrees per second to velocity command
  private: int SpeedDeg2SpeedVal(double speed, uint16_t &val);

  //convert speed feedback to degrees/second
  private: int SpeedVal2SpeedDeg(uint16_t val, double &speed);

  private: int GenerateAngleCmd(double angle, double speed, DynamixelPacket * dpacket);
  private: int GenerateFeedbackRequestCmd(DynamixelPacket * dpacket);

  private: double minAngle;
  private: double maxAngle;
  private: double desAngle;
  private: double desSpeed;
  private: double desAcceleration;
  private: double angle;
  private: double reversePoint;
  private: int state;
  private: int mode;
  private: bool freshAngle;
  private: DynamixelPacket * packetOut;
  private: Upenn::Timer cmdTimer;
  private: Upenn::Timer feedbackRequestTimer;
  private: int dir;
  private: int id;
  private: double angleTime;
  private: unsigned int angleCntr;
  private: double minLimit;
  private: double maxLimit;
  private: bool needToResetState;
};
#endif //DYNAMIXEL_CONTROLLER_HH

