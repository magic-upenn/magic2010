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

  #ifdef MEX_IPC_SERIALIZATION
    INSERT_SERIALIZATION_DECLARATIONS 
  #endif
  };
}
#endif //MAGIC_STATUS_HH

