#ifndef VEHICLE_DYNAMICS_HH
#define VEHICLE_DYNAMICS_HH

#include <stdint.h>
#include "MagicHostCom.hh"

namespace Magic
{
  class VehicleDynamics
  {
    public: VehicleDynamics();
    public: ~VehicleDynamics();

    public: int Simulate(double dt);
    public: int SetXYZ(double x, double y, double z);
    public: int SetRPY(double roll, double pitch, double yaw);
    public: int SetVW(double v, double w);

  
    public: int GetXYZ(double &x, double &y, double &z);
    public: int GetRPY(double &roll, double &pitch, double &yaw);
    public: int GetCounts(int16_t &fr, int16_t &fl, int16_t &rr, int16_t &rl);
    public: int GetCounts(EncoderCounts * counts);

    private: double x,y,z,v;
    private: double roll,pitch,yaw,wx,wy,wz,w;
  };
}
#endif //VEHICLE_DYNAMICS_HH

