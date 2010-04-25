#ifndef MAGIC_POSE_HH
#define MAGIC_POSE_HH

namespace Magic
{
  struct Pose
  {
    double x;
    double y;
    double z;
    double v;
    double w;
    double roll;
    double pitch;
    double yaw;
    double t;
    
    Pose() : x(0),y(0),z(0),v(0),w(0),roll(0),pitch(0),yaw(0),t(0) {}
    Pose(double _x, double _y, double _z, double _v, double _w, 
         double _roll, double _pitch, double _yaw, double _t) :
      x(_x), y(_y), z(_z), v(_v), w(_w), roll(_roll), pitch(_pitch), yaw(_yaw), t(_t) {}
    
    #define MagicPose_IPC_FORMAT "{double,double,double, double,double,double, double,double,double}"
    static const char * getIPCFormat() { 
      return MagicPose_IPC_FORMAT;
    }
  
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
}
#endif //MAGIC_POSE_HH

