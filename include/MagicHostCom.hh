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
}
#endif //MAGIC_HOST_COM
