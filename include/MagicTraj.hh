#ifndef MAGIC_TRAJ_HH
#define MAGIC_TRAJ_HH

#include <stdint.h>

namespace Magic
{

  struct MotionTrajWaypoint
  {
    double x;
    double y;
    double yaw;
    double v;
    
    MotionTrajWaypoint() : x(0),y(0),yaw(0),v(0) {}
    MotionTrajWaypoint(double _x, double _y, double _yaw, double _v) :
      x(_x), y(_y), yaw(_yaw), v(_v) {}
    
    #define MagicMotionTrajWaypoint_IPC_FORMAT "{double,double,double,double}"
    static const char * getIPCFormat() { 
      return MagicMotionTrajWaypoint_IPC_FORMAT;
    }
  
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
  
  
  struct MotionTraj
  {
    double t;
    int size;
    MotionTrajWaypoint * waypoints;
    
    MotionTraj() : t(0), size(0), waypoints(0) {}
    MotionTraj(double _t, int _size, MotionTrajWaypoint * _waypoints) :
      t(_t), size(_size), waypoints(_waypoints) {}
      
    //clean up
    ~MotionTraj() { if (waypoints) delete [] waypoints; waypoints = NULL;}
      
    #define MagicMotionTraj_IPC_FORMAT "{double,int,<" MagicMotionTrajWaypoint_IPC_FORMAT ":2>}"
    static const char * getIPCFormat(){
      return MagicMotionTraj_IPC_FORMAT;
    }
    
    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS 
    #endif
  };

}
#endif //MAGIC_TRAJ_HH

