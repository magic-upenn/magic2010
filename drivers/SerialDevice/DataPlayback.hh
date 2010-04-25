#ifndef DATA_PLAYBACK_HH
#define DATA_PLAYBACK_HH

#include <string>

using namespace std;

namespace Upenn
{
  class DataPlayback
  {
    //constructor    
    public: DataPlayback();

    //destructor
    public: virtual ~DataPlayback();

    //open the log with given filename
    public: virtual int Open(string filename) = 0;

    //close the log file
    public: virtual int Close() = 0;

    //set the playback speed: 1.0 is the normal speed
    public: int SetPlaySpeed(double playSpeed);

    //set the playback direction (either -1 or 1)
    public: int SetPlayDir(int playDir);

    //set the playback offset
    public: int SetPlayOffset(double offset);

    //get the next data
    public: virtual int GetData(char ** dataPtrPtr, int & dataLength, 
                                double & timestamp, string & infoStr,
                                double seekTime) = 0;

    
    protected: bool fileOpen;
    protected: double speed;
    protected: int dir;
    protected: double lastReturnedTime;
    protected: double lastLogTime;
    protected: double playStartTime;
    protected: double logStartTime;
    protected: double logPausedTime;
    protected: double playOffset;
  };
}

#endif //DATA_PLAYBACK_HH

