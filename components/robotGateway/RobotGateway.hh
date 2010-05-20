#ifndef ROBOT_GATEWAY_HH
#define ROBOT_GATEWAY_HH

#include <string>
#include <list>
#include <stdint.h>
#include <ipc.h>

using namespace std;

namespace Magic
{
  struct GatewayMsgQueueEntry
  {
    string msgName;
    double t;
    int size;
    uint8_t * data;

    GatewayMsgQueueEntry() : t(0),size(0),data(0) {}
  };

  typedef list<GatewayMsgQueueEntry> GatewayMsgQueue;

  class RobotGateway
  {
    public: RobotGateway();
    public: ~RobotGateway();

    
    public: int Connect(string remoteIp);

    //connect to the local central
    private: int ConnectLocal();

    //connect to the remote central
    private: int ConnectRemote(string remoteIp);

    private: bool connectedLocal;
    private: bool connectedRemote;
    private: GatewayMsgQueue msgQueue;
    private: string processName;
    private: IPC_CONTEXT_PTR centralLocal;
    private: IPC_CONTEXT_PTR centralRemote;
  }
}
#endif //ROBOT_GATEWAY_HH

