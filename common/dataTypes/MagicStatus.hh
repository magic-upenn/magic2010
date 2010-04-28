#ifndef MAGIC_STATUS_HH
#define MAGIC_STATUS_HH

namespace Magic
{
  struct HeartBeat
  {
    char * sender;
    char * msgName;
    int status;
    double t;

    HeartBeat() : sender(0),msgName(0),status(0),t(0) {}
    #define HeartBeat_FORMAT "{string, string, int, double}"
    
    static const char *getIPCFormat(void)
    {
      return HeartBeat_FORMAT;
    }

  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
}
#endif //MAGIC_STATUS_HH

