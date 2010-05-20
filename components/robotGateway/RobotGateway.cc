#include "RobotGateway.hh"
#include "ErrorMessage.hh"

using namespace std;
using namespace Magic;


/////////////////////////////////////////////////////////////////////////////////////
// Constructor
/////////////////////////////////////////////////////////////////////////////////////
RobotGateway::RobotGateway()
{
  this->connectedLocal  = false;
  this->connectedRemote = false;
  this->centralLocal    = NULL;
  this->centralRemote   = NULL;
}


/////////////////////////////////////////////////////////////////////////////////////
// Destructor
/////////////////////////////////////////////////////////////////////////////////////
RobotGateway::~RobotGateway()
{

}


/////////////////////////////////////////////////////////////////////////////////////
// Connect to local central
/////////////////////////////////////////////////////////////////////////////////////
int RobotGateway::Connect(string remoteIp)
{
  char * robotIdStr = getenv("ROBOT_ID");
  if (!robotIdStr)
  {
    PRINT_ERROR("ROBOT_ID must be defined\n");
    return -1;
  }

  this->processName     = string("Robot") + string(robotIdStr) + "/RobotGateway";
  IPC_setVerbosity(IPC_PRINT_ERRORS);

  if (this->ConnectLocal()
  {
    PRINT_ERROR("could not connect to local central\n");
    return -1;
  }

  if (this->ConnectRemote(remoteIp))
  {
    PRINT_ERROR("could not connect to remote central\n");
    return -1;
  }

  return 0;
}
/////////////////////////////////////////////////////////////////////////////////////
// Connect to local central
/////////////////////////////////////////////////////////////////////////////////////
int RobotGateway::ConnectLocal()
{
  if (this->connectedLocal)
  {
    PRINT_INFO("already connected to local central\n");
    return 0;
  }

  if (IPC_connectModule(this->processName.c_str(),"localhost") != IPC_OK)
  {
    PRINT_ERROR("could not connect to local central\n");
    return -1;
  }

  if (this->centralLocal = IPC_getContext() == NULL)
  {
    PRINT_ERROR("could not get local context\n");
    return -1;
  }

  this->connectedLocal = true;
  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////
// Connect to remote central
/////////////////////////////////////////////////////////////////////////////////////
int RobotGateway::ConnectRemote(string remoteIp)
{
  if (this->connectedRemote)
  {
    PRINT_INFO("already connected to remote central\n");
    return 0;
  }

  if (IPC_connectModule(this->processName.c_str(),remoteIp.c_str()) != IPC_OK)
  {
    PRINT_ERROR("could not connect to remote central\n");
    return -1;
  }

  if (this->centralRemote = IPC_getContext() == NULL)
  {
    PRINT_ERROR("could not get remote context\n");
    return -1;
  }

  return 0;

}








