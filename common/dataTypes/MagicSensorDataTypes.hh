#ifndef MAGIC_SENSOR_DATA_TYPES_HH
#define MAGIC_SENSOR_DATA_TYPES_HH

#ifndef  __APPLE__
#include "VisDataTypes.hh"
#else
#include <Vis/VisDataTypes.hh>
#endif

#include <string.h>

using namespace vis;

namespace Magic
{
  struct LidarScan
  {
    uint32_t      counter;
    uint32_t      id;
    FloatArray    ranges ;
    UInt16Array   intensities ;

    float         startAngle ; // radians
    float         stopAngle ;  // radians
    float         angleStep ;  // radians
    double        startTime ;  // seconds
    double        stopTime ;   // seconds

    #define MagicLidarScan_IPC_FORMAT "{ uint, uint," FloatArray_IPC_FORMAT \
                                 ", " UInt16Array_IPC_FORMAT ", "\
                                 " float, float, float, double, double}"

    static const char*  getIPCFormat() { return MagicLidarScan_IPC_FORMAT; };
    
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };

  struct ServoState
  {
    uint32_t  counter;
    uint32_t  id;
    float     position ;     // radians
    float     velocity ;     // radians / sec
    float     acceleration ; // radians / sec^2
    double    t;     // seconds

    #define MagicServoState_IPC_FORMAT "{ uint, uint, float, float, float, double }"

    static const char*  getIPCFormat() { return MagicServoState_IPC_FORMAT; };

  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
  
  struct ImuFiltered
  {
    double roll;
    double pitch;
    double yaw;
    double wroll;
    double wpitch;
    double wyaw;
    double t;
    
    #define MagicImuFiltered_IPC_FORMAT "{double,double,double,double,double,double,double}"
    
    static const char* getIPCFormat() { return MagicImuFiltered_IPC_FORMAT; };
    
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
}

#endif //MAGIC_SENSOR_DATA_TYPES_HH

