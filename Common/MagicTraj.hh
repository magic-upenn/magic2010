#ifndef MAGIC_TRAJ_HH
#define MAGIC_TRAJ_HH

#include <stdint.h>

namespace Magic
{

  struct TrajWaypoint
  {
    double x;
    double y;
    double yaw;
    double v;
    
    TrajWaypoint() : x(0),y(0),yaw(0),v(0) {}
    TrajWaypoint(double _x, double _y, double _yaw, double _v) :
      x(_x), y(_y), yaw(_yaw), v(_v) {}
    
    #define MagicTrajWaypoint_IPC_FORMAT "{double,double,double,double}"
    static const char * getIPCFormat() { 
      return MagicTrajWaypoint_IPC_FORMAT;
    }
  
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
  
  
  struct Traj
  {
    double t;
    int size;
    TrajWaypoint * waypoints;
    
    Traj() : t(0), size(0), waypoints(0) {}
    Traj(double _t, int _size, TrajWaypoint * _waypoints) :
      t(_t), size(_size), waypoints(_waypoints) {}
      
    //clean up
    ~Traj() { if (waypoints) delete [] waypoints; waypoints = NULL;}
      
    #define MagicTraj_IPC_FORMAT "{double,int,<" MagicTrajWaypoint_IPC_FORMAT ":2>}"
    static const char * getIPCFormat(){
      return MagicTraj_IPC_FORMAT;
    }
    
    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS 
    #endif
  }

}
#endif //MAGIC_TRAJ_HH
