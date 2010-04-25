#ifndef MAGIC_HOST_COM_HH
#define MAGIC_HOST_COM_HH

#include <stdint.h>
#include <string.h>

namespace Magic
{

  struct IpcRawDynamixelPacket
  {
    double t;
    int size;
    uint8_t * data;
    IpcRawDynamixelPacket() : t(0),size(0),data(0) {}
    #define IpcRawDynamixelPacket_FORMAT "{double, int, <ubyte: 2>}"
    
    static const char *getIPCFormat(void)
    {
      return IpcRawDynamixelPacket_FORMAT;
    }
    
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
  
  struct Trajectory
  {
  
  
  
  };

  struct VelocityCmd
  {
    double t;
    double v;
    double w;

    VelocityCmd(): t(0), v(0), w(0) {}
    VelocityCmd(double _t, double _v, double _w): t(_t), v(_v), w(_w) {}

    #define MagicVelocityCmd_FORMAT "{double,double,double}"

    static const char *getIPCFormat(void)
    {
      return MagicVelocityCmd_FORMAT;
    }

    #ifdef MEX_IPC_SERIALIZATION
      INSERT_SERIALIZATION_DECLARATIONS
    #endif
  };
  
}
#endif //MAGIC_HOST_COM
