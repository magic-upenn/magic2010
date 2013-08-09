#ifndef DATA_LOGGER_QUEUE_HH
#define DATA_LOGGER_QUEUE_HH

#include <string>
#include <iostream>
#include <fstream>
#include <pthread.h>
#include <unistd.h>
#include "PointerQueueBuffer.hh"
#include "Timer.hh"
#include "DataLogger.hh"

#define DATA_LOGGER_QUEUE_UPDATE_FUNCTION_ERROR_SLEEP_US 10000
#define DATA_LOGGER_QUEUE_MAX_NUM_CONSECUTIVE_ERRORS 10
#define DATA_LOGGER_QUEUE_DEF_FLUSH_PERIOD 5.0

using namespace std;

namespace Upenn
{
  class DataLoggerQueue : public DataLogger
  {
    //constructor
    public: DataLoggerQueue(int maxLength = POINTER_QUEUE_BUFFER_DEF_MAX_LENGTH);

    //destructor
    public: ~DataLoggerQueue();

    //write data to the output file
    public: virtual int Write(QBData * qbd); 

    protected: virtual int UpdateFunction() = 0;

    protected: int StartThread();
    protected: int StopThread();
    

    protected: PointerQueueBuffer * pqBuf;
    protected: int maxQueueLength;

    protected: bool threadRunning;
    protected: pthread_t thread;
    private: static void *ThreadFunc(void * input);
    protected: double flushPeriod;
    
  };
}

#endif //DATA_LOGGER_QUEUE_HH
