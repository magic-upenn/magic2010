#ifndef DATA_LOGGER_HH
#define DATA_LOGGER_HH

#include <string>
#include "PointerQueueBuffer.hh"

#define DATA_LOGGER_LOG_EXT ".log.data"
#define DATA_LOGGER_INFO_EXT ".log.info"
#define DATA_LOGGER_HEAD_EXT ".log.head"
//#define DATA_LOGGER_INFO_HEADER_SEPARATOR "**********"

using namespace std;

namespace Upenn
{
  class DataLogger
  {
    //constructor
    public: DataLogger();

    //destructor
    public: virtual ~DataLogger();

    //open the file for writing
    public: virtual int Open(string filename, string header=string("")) = 0;

    //close the file
    public: virtual int Close() = 0;

    //write data to the output file
    public: virtual int Write(QBData * qbd) = 0;

    //flush the log
    public: virtual int Flush() = 0;

    //check to see if the log is syncing
    public: virtual bool IsBusy();

    protected: void SetBusy(bool b);

    //lock the mutex
	  private: void LockDataMutex();

    //unlock the mutex
	  private: void UnlockDataMutex();

    private: pthread_mutex_t  dataMutex;            //mutex for proper reading / writing in threads
    private: bool busy;
    protected: bool loggerOpen;
  };
}

#endif //DATA_LOGGER_HH
