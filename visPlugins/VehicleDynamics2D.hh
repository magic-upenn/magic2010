#ifndef VEHICLE_DYNAMICS_2D_HH
#define VEHICLE_DYNAMICS_2D_HH

#include <stdint.h>
#include "MagicSensorDataTypes.hh"
#include <math.h>

#define VEHICLE_DYNAMICS_MAX_V 2.0
#define VEHICLE_DYNAMICS_MIN_V -2.0

#define VEHICLE_DYNAMICS_MAX_W M_PI/2.0
#define VEHICLE_DYNAMICS_MIN_W -M_PI/2.0

namespace Magic
{
  class VehicleDynamics2D
  {
    public: VehicleDynamics2D();
    public: ~VehicleDynamics2D();

    //simulate the dynamics for dt
    public: int Simulate(double dt);
    
    //set the current values
    public: int SetXYZ(double x, double y, double z);
    public: int SetRPY(double roll, double pitch, double yaw);
    
    //set desired velocities
    public: int SetDesVW(double vDes, double wDes);

    //get the current values
    public: int GetXYZ(double &x, double &y, double &z);
    public: int GetRPY(double &roll, double &pitch, double &yaw);
    public: int GetWRPY(double &wroll, double &wpitch, double &wyaw);

    public: int GetCounts(uint16_t &cntr, int16_t &fr, int16_t &fl, 
                          int16_t &rr, int16_t &rl);
    public: int GetCounts(EncoderCounts * counts);

    private: void ResetCounts();

    private: double x,y,z,v,vx,vy,vz;
    private: double roll,pitch,yaw,wx,wy,wz,w;
    
    private: double vDes,wDes;
    
    private: double fr, fl, rr, rl;
    private: uint16_t cntr;
    private: double vmin,vmax,wmin,wmax;
  };
}
#endif //VEHICLE_DYNAMICS_2D_HH

