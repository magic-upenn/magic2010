#ifndef MAGIC_STATUS_HH
#define MAGIC_STATUS_HH

#include <string>
#include "Timer.hh"
#include <ipc.h>
#include <iostream>
#include "ErrorMessage.hh"

using namespace std;

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
  
  class HeartBeatPublisher
  {
    public:
    HeartBeatPublisher()
    {
    
    }
    
    ~HeartBeatPublisher()
    {
    
    }
    
    int Initialize(char * sender, char * msgName)
    {
      this->sender    = string(sender);
      this->msgName   = string(msgName);
      string robotId  = getenv("ROBOT_ID");
      if (robotId.empty())
      {
        PRINT_ERROR("ROBOT_ID environmental variable must be defined\n");
        return -1;
      }
      
      this->ipcMsgName = string("Robot") + robotId + "/HeartBeat";
      
      if (IPC_defineMsg(this->ipcMsgName.c_str(),IPC_VARIABLE_LENGTH,Magic::HeartBeat::getIPCFormat()) != IPC_OK)
      {
        PRINT_ERROR("could not define heartbeat message for: "<<this->msgName<<"\n");
        return -1;
      }
      
      this->heartBeat.sender  = (char*)this->sender.c_str();
      this->heartBeat.msgName = (char*)this->msgName.c_str();
      
      return 0;
    }
    
    int Publish(int status = 0)
    {
      this->heartBeat.status = status;
      this->heartBeat.t      = Upenn::Timer::GetAbsoluteTime();
      if (IPC_publishData(ipcMsgName.c_str(),&(this->heartBeat)) != IPC_OK)
      {
        PRINT_ERROR("could not publish heartbeat message for: " << this->msgName << "\n");
        return -1;
      }
    
      return 0;
    }
    
    private:
      string sender;
      string msgName;
      string ipcMsgName;
      Magic::HeartBeat heartBeat;
  
  };
}
#endif //MAGIC_STATUS_HH

