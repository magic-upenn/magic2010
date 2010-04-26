#include "VehicleDynamics2D.hh"
#include "Timer.hh"

using namespace Magic;
using namespace Upenn;


VehicleDynamics2D::VehicleDynamics2D()
{
  this->x = 0;
  this->y = 0;
  this->z = 0;
  this->v = 0;
  this->vx = 0;
  this->vy = 0;
  this->vz = 0;

  this->roll = 0;
  this->pitch = 0;
  this->yaw = 0;
  this->wx = 0;
  this->wy = 0;
  this->wz = 0;
  this->w = 0;
  
  
  this->vDes =0;
  this->wDes =0;
  
  this->cntr =0;
  
  this->vmin = VEHICLE_DYNAMICS_MIN_V;
  this->vmax = VEHICLE_DYNAMICS_MAX_V;
  this->wmin = VEHICLE_DYNAMICS_MIN_W;
  this->wmax = VEHICLE_DYNAMICS_MAX_W;
  
  
  this->ResetCounts();
}

VehicleDynamics2D::~VehicleDynamics2D()
{
}


int VehicleDynamics2D::Simulate(double dt)
{

  //TODO: add dynamics to velocity
  this->v = this->vDes;
  this->w = this->wDes;

 
  if (this->v > this->vmax) this->v = this->vmax;
  if (this->v < this->vmin) this->v = this->vmin;
  if (this->w > this->wmax) this->w = this->wmax;
  if (this->w < this->wmin) this->w = this->wmin;

  //simulate differential drive dynamics
  bool wIsNonZero=fabs(this->w) > 0.001;
  
  int nCountsPerMeter = 500; //???
  double r = 0.22; //robot radius
  
  int16_t right = (this->v + this->w*r)*nCountsPerMeter;
  int16_t left  = (this->v - this->w*r)*nCountsPerMeter;
  
  this->fr += right;
  this->rr += right;
  this->fl += left;
  this->rl += left;

  double sinTh=sin(this->yaw);
  double cosTh=cos(this->yaw);
  double Vdt=this->v*dt;
  
  if (wIsNonZero)
  {
    //precompute
    double thWDt=this->yaw + this->w*dt;
    double sinThWDt=sin(thWDt);
    double cosThWDt=cos(thWDt);
    double VoverW=this->v/this->w;

    //update the expected values
    this->x   += VoverW*(sinThWDt-sinTh);
    this->y   += VoverW*(cosTh-cosThWDt);
    this->yaw  = thWDt;

  } 
  else 
  {
    //precompute
    double Vdt=this->v*dt;
    double VdtCosTh=Vdt*cosTh;
    double VdtSinTh=Vdt*sinTh;

    //update the expected values
    this->x   += VdtCosTh;
    this->y   += VdtSinTh;
    this->yaw += this->w*dt;
  }

  return 0;
}


int VehicleDynamics2D::SetXYZ(double x, double y, double z)
{
  this->x = x;
  this->y = y;
  this->z = z;

  return 0;
}

int VehicleDynamics2D::SetRPY(double roll, double pitch, double yaw)
{
  this->roll  = roll;
  this->pitch = pitch;
  this->yaw   = yaw;

  return 0;
}

int VehicleDynamics2D::SetDesVW(double vDes, double wDes)
{
  this->vDes = vDes;
  this->wDes = wDes;
  
  return 0;
}



int VehicleDynamics2D::GetXYZ(double &x, double &y, double &z)
{
  x = this->x;
  y = this->y;
  z = this->z;
  return 0;
}

int VehicleDynamics2D::GetRPY(double &roll, double &pitch, double &yaw)
{
  roll  = this->roll;
  pitch = this->pitch;
  yaw   = this->yaw;
  return 0;
}


int VehicleDynamics2D::GetCounts(uint16_t &cntr, int16_t &fr, int16_t &fl, int16_t &rr, int16_t &rl)
{
  cntr = this->cntr;
  fr   = this->fr;
  fl   = this->fl;
  rr   = this->rr;
  rl   = this->rl;
  
  //reset the counts
  this->ResetCounts();
  
  return 0;
}


int VehicleDynamics2D::GetCounts(EncoderCounts * counts)
{
  counts->t    = Timer::GetAbsoluteTime();
  counts->cntr = this->cntr;
  counts->fr   = this->fr;
  counts->fl   = this->fl;
  counts->rr   = this->rr;
  counts->rl   = this->rl;

  //reset the counts
  this->ResetCounts();

  return 0;
}

void VehicleDynamics2D::ResetCounts()
{
  this->fr = 0;
  this->fl = 0;
  this->rr = 0;
  this->rl = 0;
  this->cntr++;
}

