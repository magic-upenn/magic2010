#ifndef MAGIC_SENSOR_DATA_TYPES_HH
#define MAGIC_SENSOR_DATA_TYPES_HH

#include "VisDataTypes.hh"
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

    static const char*  getIPCFormat() { return MagicLidarScan_IPC_FORMAT; }
    
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
    double    t;             // seconds

    #define MagicServoState_IPC_FORMAT "{ uint, uint, float, float, float, double }"

    static const char*  getIPCFormat() { return MagicServoState_IPC_FORMAT; }

  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };

  struct ServoControllerCmd
  {
    int id;
    int mode;
    double minAngle;
    double maxAngle;
    double speed;
    double acceleration;
    double t;

    ServoControllerCmd() : id(0),mode(0),minAngle(0),maxAngle(0),speed(0),acceleration(0),t(0) {}
    #define MagicServoController_IPC_FORMAT "{int,int,double,double,double,double,double}"

    static const char * getIPCFormat() { return MagicServoController_IPC_FORMAT; }

  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif

  };

  struct ImuRaw
  {
    uint16_t cntr;
    uint16_t rawAx;
    uint16_t rawAy;
    uint16_t rawAz;
    uint16_t rawWx;
    uint16_t rawWy;
    uint16_t rawWz;
    uint16_t rawMx;
    uint16_t rawMy;
    uint16_t rawMz;

    double t;

    #define MagicImuRaw_IPC_FORMAT "{ushort,ushort,ushort,ushort,ushort,ushort,ushort,ushort,ushort,ushort,double}"
    
    static const char* getIPCFormat() { return MagicImuRaw_IPC_FORMAT; }
    
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
    
    static const char* getIPCFormat() { return MagicImuFiltered_IPC_FORMAT; }
    
  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };

  struct GpsASCII
  {
    double t;
    int id;
    int size;
    uint8_t * data;

    GpsASCII() : t(0), id(0), size(0), data(0) {}
    GpsASCII(double _t, int _id, int _size, uint8_t * _data) : t(_t), id(_id), size(_size), data(_data) {}
    #define MagicGpsASCII_FORMAT "{double, int, int, <ubyte: 3>}"

    static const char *getIPCFormat(void)
    {
      return MagicGpsASCII_FORMAT;
    }
    
    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif
    
  };


  struct EncoderCounts
  {
    double t;
    uint16_t cntr;
    int16_t fr;
    int16_t fl;
    int16_t rr;
    int16_t rl;

    EncoderCounts() : t(0), cntr(0), fr(0), fl(0), rr(0), rl(0) {}
    EncoderCounts(double _t, uint16_t _cntr, int16_t _fr, int16_t _fl, int16_t _rr, int16_t _rl) :
      t(_t), cntr(_cntr), fr(_fr), fl(_fl), rr(_rr), rl(_rl) {}

    #define MagicEncoderCounts_FORMAT "{double, ushort, short, short, short, short}"

    static const char *getIPCFormat(void)
    {
      return MagicEncoderCounts_FORMAT;
    }
    
    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif
  };

  struct VelocityCmd
  {
    double t;
    double v;
    double w;
    int vCmd;
    int wCmd;

    VelocityCmd(): t(0), v(0), w(0), vCmd(0), wCmd(0) {}
    VelocityCmd(double _t, double _v, double _w, int _vCmd, int _wCmd): 
         t(_t), v(_v), w(_w), vCmd(_vCmd), wCmd(_wCmd) {}

    #define MagicVelocityCmd_FORMAT "{double,double,double,int,int}"

    static const char *getIPCFormat(void)
    {
      return MagicVelocityCmd_FORMAT;
    }

    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif
  };

  struct EstopState
  {
    int state;   //0=run, 1= freeze, 2=disable
    double t;

    EstopState(): state(-1),t(0) {}
    EstopState(int _state, double _t) : state(_state), t(_t) {}
    
    #define MagicEstopState_FORMAT "{int, double}"

    static const char *getIPCFormat(void)
    {
      return MagicEstopState_FORMAT;
    }

    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif
  };

  struct BatteryStatus
  {
    double voltage;
    double current;
    double age;
    double charge;
    double t;

    BatteryStatus() : voltage(0), current(0), age(0), charge(0), t(0) {}

    #define MagicBatteryStatus_FORMAT "{double,double,double,double,double}"

    static const char *getIPCFormat(void)
    {
      return MagicBatteryStatus_FORMAT;
    }

    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif

  };

  struct MotorStatus
  {
    double currentFR;
    double currentFL;
    double currentRR;
    double currentRL;

    double tempFR;
    double tempFL;
    double tempRR;
    double tempRL;

    double t;

    MotorStatus(): currentFR(0), currentFL(0), currentRR(0), currentRL(0), tempFR(0), tempFL(0), tempRR(0), tempRL(0), t(0) {}

    #define MagicMotorStatus_FORMAT "{double,double,double,double,double,double,double,double,double}"

    static const char *getIPCFormat(void)
    {
      return MagicMotorStatus_FORMAT;
    }


    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif

  };
}

#endif //MAGIC_SENSOR_DATA_TYPES_HH


