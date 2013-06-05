#ifndef DATA_PLAYBACK_DB_HH
#define DATA_PLAYBACK_DB_HH

#include "DataPlayback.hh"
#include <string>
#include <vector>
#include <db_cxx.h>
#include "Timer.hh"
#include "fstream"

using namespace std;

namespace Upenn
{
  class DataPlaybackDB : public DataPlayback
  {
    public: DataPlaybackDB();

    public: ~DataPlaybackDB();

    public: int Open(string filename);

    public: int Close();

    //get the next data
    public: int GetData(char ** dataPtrPtr, int & dataLength, 
                        double & timestamp, string & infoStr,
                        double seekTime);
                        
    public: ifstream & GetHeader();
    
    public: double GetLogStartTime();

    
    protected: Db * db;
    protected: Dbc * dbc;
    protected: Dbc * dbcFirst;
    protected: Dbc * dbcLast;
    protected: ifstream infoStream;
    protected: ifstream headStream;
    protected: vector<double> timestamps;
    protected: vector<string> info;
    protected: string header;
    private: bool firstTime;
    private: double initSeekTime;
  };
}
#endif
