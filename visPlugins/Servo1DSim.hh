#ifndef SERVO_1D_SIM_HH
#define SERVO_1D_SIM_HH

//everything is in degrees
#define SERVO_1D_SIM_DEF_POS        0
#define SERVO_1D_SIM_DEF_VEL        0
#define SERVO_1D_SIM_DEF_MIN_POS   -180
#define SERVO_1D_SIM_DEF_MAX_POS    180
#define SERVO_1D_SIM_DEF_MAX_SPEED  20
#define SERVO_1D_SIM_DEF_MAX_ACCEL  200
#define SERVO_1D_SIM_DEF_RAMP_ACCEL 100
#define SERVO_1D_SIM_DEF_DDT        0.001
#define SERVO_1D_SIM_DEF_TARGET     0
#define SERVO_1D_SIM_DEF_KD         1000
 

namespace Upenn
{
  class Servo1DSim
  {
    //constructor
    public: Servo1DSim();
    
    //destructor
    public: ~Servo1DSim();
    
    //initialize / reset the simulator
    public: int Reset(double pos, double vel);
    
    //simulate the servo motion for dt period
    public: int Simulate(double dt);

    //set the target angle
    public: int SetTarget(double target);
    
    //set the maximum speed
    public: int SetMaxSpeed(double maxSpeed);
    
    //set the minimum position
    public: int SetMinPos(double minPos);
    
    //set the maximum position
    public: int SetMaxPos(double maxPos);
    
    //set the maximum acceleration
    public: int SetMaxAccel(double maxAccel);

    //set the ramp acceleration
    public: int SetRampAccel(double rampAccel);
    
    //get the current position
    public: int GetPos(double & pos);
    
    //get the current velocity
    public: int GetVel(double & vel);

    public: int SetContinuous(bool val);

    private: double NormalizeR(double angle);
    private: double NormalizeD(double angle);
    

    //current servo angle
    private: double pos;
    private: double vel;
    private: double target;
    private: double ddt;
    private: double kd;
    
    private: double minPos;
    private: double maxPos;
    private: double maxSpeed;
    private: double maxAccel;
    private: double rampAccel;
    private: bool continuous;
  };
}
#endif

