#include "DataLoggerQueue.hh"
#include "ErrorMessage.hh"

using namespace Upenn;
using namespace std;

DataLoggerQueue::DataLoggerQueue(int maxLength)
{
  this->pqBuf                 = NULL;
  this->threadRunning         = false;
  this->maxQueueLength        = maxLength;
  this->flushPeriod           = DATA_LOGGER_QUEUE_DEF_FLUSH_PERIOD;
}

DataLoggerQueue::~DataLoggerQueue()
{
  if (this->pqBuf) delete this->pqBuf;
}


int DataLoggerQueue::Write(QBData * qbd)
{
  if (!this->pqBuf)
  {
    PRINT_ERROR("buffer is null\n");
    return -1;
  } 
 
  if (this->pqBuf->Push(qbd))
  {
    PRINT_ERROR("could not insert data into queue\n");
    return -1;
  }
  
  return 0;
}

//start the main thread
int DataLoggerQueue::StartThread()
{
	
	PRINT_INFO("Starting thread...");

  if (pthread_create(&this->thread, NULL, this->ThreadFunc, (void *)this))
  {
    PRINT_ERROR("Could not start thread\n");
    return -1;
  }
  PRINT_INFO("done\n");

	this->threadRunning=true;
	return 0;
}

int DataLoggerQueue::StopThread()
{
	if (this->threadRunning)
  {
    PRINT_INFO("Stopping thread..."); 
    pthread_cancel(this->thread);
    pthread_join(this->thread,NULL);
    PRINT_INFO("done\n"); 
    this->threadRunning=false;
  }

	return 0;
}

//dummy function for running the main loop
void *DataLoggerQueue::ThreadFunc(void * arg_in)
{
	sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

	DataLoggerQueue * dl = (DataLoggerQueue *) arg_in;
  
  int nErrorsTotal=0;
  int nErrorsConsecutive=0;

	while(1)
  {
    //see if we need to cancel the thread		
    pthread_testcancel();

    //run the update function
		if (dl->UpdateFunction() != 0)
    {
      nErrorsTotal++;
      nErrorsConsecutive++;
      if (nErrorsConsecutive >= DATA_LOGGER_QUEUE_MAX_NUM_CONSECUTIVE_ERRORS)
      {
        PRINT_ERROR("**********************************************\n");        
        PRINT_ERROR("exiting because of too many consecutive errors\n");
        PRINT_ERROR("**********************************************\n");
        pthread_exit(NULL);
      }
      usleep(DATA_LOGGER_QUEUE_UPDATE_FUNCTION_ERROR_SLEEP_US);
    }
    else
    {
      //reset the consecutive error count
      nErrorsConsecutive=0;
    }
	}
}

