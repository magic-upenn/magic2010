#include "Servo1DSim.hh"
#include "ErrorMessage.hh"
#include "math.h"

using namespace std;
using namespace Upenn;

Servo1DSim::Servo1DSim()
{
  this->pos       = SERVO_1D_SIM_DEF_POS;
  this->vel       = SERVO_1D_SIM_DEF_VEL;
  this->minPos    = SERVO_1D_SIM_DEF_MIN_POS;
  this->maxPos    = SERVO_1D_SIM_DEF_MAX_POS;
  this->maxSpeed  = SERVO_1D_SIM_DEF_MAX_SPEED;
  this->maxAccel  = SERVO_1D_SIM_DEF_MAX_ACCEL;
  this->rampAccel = SERVO_1D_SIM_DEF_RAMP_ACCEL;
  this->target    = SERVO_1D_SIM_DEF_TARGET;
  this->ddt       = SERVO_1D_SIM_DEF_DDT;
  this->kd        = SERVO_1D_SIM_DEF_KD;
  this->continuous= false;
}

Servo1DSim::~Servo1DSim()
{
}

int Servo1DSim::Reset(double pos, double vel)
{
  this->pos = pos;
  this->vel = vel;
  return 0;
}

int Servo1DSim::Simulate(double dt)
{
  //number of steps (round up)
  int nSteps = dt/ddt + 0.49;
  double ddt2 = ddt*ddt;
  
  for (int ii=0; ii<nSteps; ii++)
  {
    //position error
    double dpos;
    if (this->continuous)
      dpos   = this->NormalizeD(this->target - this->pos);
    else
      dpos   = this->target - this->pos;
    

    //given ramp deceleration, what should the current velocity
    //be, so that the servo stops exactly at the desired position 
    double velDes = sqrt(2*this->rampAccel*fabs(dpos));

    //cap the velocity - this makes trapezoidal velocity profile
    if (velDes > this->maxSpeed)
      velDes = this->maxSpeed;
    
    //assign the appropriate sign
    if (dpos < 0)
      velDes *= -1;
      
    //proportional control on velocity
    double dvel = velDes - this->vel;

    //instantaneous desired acceleration
    double accel = dvel * kd;
    
    //cap the acceleration
    if ( (accel > 0) && (accel > this->maxAccel) )
      accel = this->maxAccel;
    else if ( (accel < 0) && (-accel > this->maxAccel) )
      accel = -this->maxAccel;

    //update the position by integrating
    this->pos += accel*ddt2/2.0 + this->vel*ddt;
    
    //update the velocity
    this->vel += accel*ddt;
  }

  return 0;
}


int Servo1DSim::SetTarget(double target)
{
  if ( (target > this->maxPos) || (target < this->minPos) )
  {
    PRINT_ERROR("target angle out of range\n");
    return -1;
  }

  this->target = target;
  return 0;
}

int Servo1DSim::SetMaxSpeed(double maxSpeed)
{
  this->maxSpeed = maxSpeed;
  return 0;
}

int Servo1DSim::SetMinPos(double minPos)
{
  this->minPos = minPos;
  return 0;
}

int Servo1DSim::SetMaxPos(double maxPos)
{
  this->maxPos = maxPos;
  return 0;
}

int Servo1DSim::SetMaxAccel(double maxAccel)
{
  this->maxAccel = maxAccel;
  return 0;
}

int Servo1DSim::SetRampAccel(double rampAccel)
{
  this->rampAccel = rampAccel;
  return 0;
}

int Servo1DSim::GetPos(double & pos)
{
  pos = this->pos;
  return 0;
}

int Servo1DSim::GetVel(double & vel)
{
  vel = this->vel;
  return 0;
}

int Servo1DSim::SetContinuous(bool val)
{
  this->continuous = val;
  return 0;
}

double Servo1DSim::NormalizeR(double angle)
{
  while (angle > M_PI) angle -= 2*M_PI;
  while (angle < -M_PI) angle += 2*M_PI;
  return angle;
}

double Servo1DSim::NormalizeD(double angle)
{
  while (angle > 180.0) angle -= 2*180.0;
  while (angle < -180.0) angle += 2*180.0;
  return angle;
}



