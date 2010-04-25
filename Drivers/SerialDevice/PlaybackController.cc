#include "PlaybackController.hh"
#include "ErrorMessage.hh"
#include <ipc.h>
#include "IpcWrapper.hh"
#include "IpcHelper.hh"
#include "EnvUtilsInterface.hh"

using namespace std;
using namespace Upenn;

PlaybackController::PlaybackController()
{
  this->connected   = false;
  this->fresh       = false;
  this->controlData = NULL;
  pthread_mutex_init( &(this->mutex) , NULL );
}


PlaybackController::~PlaybackController()
{
  pthread_mutex_destroy(&(this->mutex));
}

int PlaybackController::Connect()
{
  if (this->connected)
  {
    PRINT_WARNING("already connected\n");
    return 0;
  }
  
  const char * msgName = PLAYBACK_INFO_REQUEST_MSG_NAME;
  
  if (IpcWrapperDefineMsg(msgName,PlaybackInfoRequest::getIPCFormat()) != 0)
                          
  {
    PRINT_ERROR("could not define message\n");
    return -1;
  }
  

/*  
  PlaybackInfoRequest request;
  PlaybackInfo * response;
  unsigned int timeoutMs = PLAYBACK_CONTROLLER_INFO_REQUEST_TIMEOUT_MS;
  
  if (IpcWrapperQueryResponseData(msgName,&request,(void**)&response,timeoutMs) != 0)
  {
    PRINT_ERROR("could not get playback info\n");
    return -1;
  }
  
  //save data locally
  this->logStartTime  = response->logStartTime;
  this->playStartTime = response->playStartTime;

  //free the response data
  IpcWrapperFreeData(PlaybackInfo::getIPCFormat(),response);
*/

  if (IpcWrapperSubscribeData(PLAYBACK_CONTROL_MSG_NAME,this->PlaybackControlMsgHandler,this) != 0)
  {
    PRINT_ERROR("could not subscribe to playback control data\n");
    return -1;
  }
  
  this->connected = true;

  return 0;
}

int PlaybackController::GetControls(PlaybackControlData * controlData)
{
  int ret;  
    
  this->LockMutex();
  if (!this->fresh)
  {
    ret = -1;
  }
  else
  {
    memcpy(controlData,this->controlData,sizeof(PlaybackControlData));
    ret = 0;
    this->fresh = false;
  }

  this->UnlockMutex();
  
  return ret;
}

int PlaybackController::Disconnect()
{
  return 0;
}

bool PlaybackController::IsFresh()
{
  bool ret;
  this->LockMutex();
  ret = this->fresh;
  this->UnlockMutex();
  return ret;
}

void PlaybackController::PlaybackControlMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData)
{
  PlaybackController * controller = (PlaybackController*)clientData;

  controller->LockMutex();

  if (controller->controlData != NULL)
  {
    //free old IPC data			
	  IpcWrapperFreeData(IPC_msgInstanceFormatter(msgRef),controller->controlData);
  }

  controller->controlData  = (PlaybackControlData*)callData;
  controller->fresh = true;

  controller->UnlockMutex();

}

int PlaybackController::LockMutex()
{
  return pthread_mutex_lock( &this->mutex );
}

int PlaybackController::UnlockMutex()
{
  return pthread_mutex_unlock( &this->mutex );
}

int PlaybackController::GetLogStartTime(double & time)
{

  return 0;
}

int PlaybackController::GetPlayStartTime(double & time)
{

  return 0;
}

