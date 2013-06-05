#ifndef PLAYBACK_CONTROLLER_HH
#define PLAYBACK_CONTROLLER_HH

#include <string>
#include "EnvUtilsInterface.hh"
#include <ipc.h>

#define PLAYBACK_CONTROLLER_INFO_REQUEST_TIMEOUT_MS 50

using namespace std;

namespace Upenn
{
  
  class PlaybackController
  {
    public: PlaybackController();
    
    public: ~PlaybackController();
    
    public: int Connect();
    public: int Disconnect();
    
    public: int GetLogStartTime(double & time);
    public: int GetPlayStartTime(double & time);
    
    public: bool IsFresh();
    public: int GetControls(PlaybackControlData * controlData);

    private: int LockMutex();
    private: int UnlockMutex();
    
    private: bool connected;
    private: bool fresh;
    private: PlaybackControlData * controlData;
    private: double logStartTime;
    private: double playStartTime;
    private: pthread_mutex_t mutex;
    private: void static PlaybackControlMsgHandler(MSG_INSTANCE msgRef, 
                                  BYTE_ARRAY callData, void *clientData); 

  };
}
#endif //PLAYBACK_CONTROLLLER_HH
