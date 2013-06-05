#ifndef DATA_LOGGER_QUEUE_DB_HH
#define DATA_LOGGER_QUEUE_DB_HH

#include <string>
#include <iostream>
#include <fstream>
#include "Timer.hh"
#include "DataLoggerQueue.hh"
#include "PointerQueueBuffer.hh"
#include "DbWrite.hh"

using namespace std;

namespace Upenn
{
  class DataLoggerQueueDB : public DataLoggerQueue, public DbWrite
  {
    //constructor
    public:  DataLoggerQueueDB(bool bufferedLog = true, 
                  int maxLength = POINTER_QUEUE_BUFFER_DEF_MAX_LENGTH, 
                  int newLogType = 0);

    //destructor
    public: ~DataLoggerQueueDB();

    //open the file for writing
    public:  int Open(string filename, string header = string(""));

    //write data to the output file
    public: virtual int Write(QBData * qbd);

    //get the used pointers so that they can be freed
    public: int GetDone(list<QBData> & done);

    public: int SetFlushPeriod(double period);

    //close the file
    public:  int Close();
    private: int Flush();
    private: int UpdateFunction();
    private: int LogOneEntry();

    private: bool buffered;
    private: int logType;
  };
}

#endif //DATA_LOGGER_CIRCULAR_FILE_HH
