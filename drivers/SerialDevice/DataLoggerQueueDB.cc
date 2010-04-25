#include "DataLoggerQueueDB.hh"
#include "ErrorMessage.hh"

using namespace Upenn;
using namespace std;

DataLoggerQueueDB::DataLoggerQueueDB(bool bufferedLog, 
                                     int maxLength, 
                                     int newLogType) 
  : DataLoggerQueue(maxLength)
{
  this->logType                   = newLogType;
  this->buffered                  = bufferedLog;
}

DataLoggerQueueDB::~DataLoggerQueueDB()
{
  this->Close();
}

int DataLoggerQueueDB::Open(string filename, string header)
{
  if (this->loggerOpen)
  {
    PRINT_ERROR("file is already open\n");
    return -1;
  }

  if (this->OpenDb(filename,header))
  {
    PRINT_ERROR("could not open db\n");
    return -1;
  }
  
  if (this->buffered)
  {
    this->pqBuf = new PointerQueueBuffer();
    if (!this->pqBuf)
    {
      PRINT_ERROR("could not create instance of circular buffer\n");
      return -1;
    }

    //start the thread
    if ( this->StartThread() )
    {
      PRINT_ERROR("could not start thread\n");
      return -1;
    }
  }

  this->loggerOpen = true;  
  return 0;
}

int DataLoggerQueueDB::Close()
{
  PRINT_INFO("closing the logger\n");
  if (this->buffered)
  {
    PRINT_INFO("waiting for the buffer to become idle\n");
    while(!this->pqBuf->IsEmpty())
      usleep(10000);
    PRINT_INFO("done\n");

    PRINT_INFO("waiting for the database to sync\n");
    while(this->IsBusy())
      usleep(10000);
    PRINT_INFO("done\n");

    //stop thread 
    if (this->StopThread())
      PRINT_WARNING("could not successfully stop the thread\n");
  }

  this->CloseDb();

  this->loggerOpen = false;
  return 0;
}


int DataLoggerQueueDB::Write(QBData * qbd)
{
  static double lastSaved = Upenn::Timer::GetAbsoluteTime();
 
  //if buffered, then let the DataLoggerQueue implementation push
  //the data into the circular buffer
  if (this->buffered)
  {
    //PRINT_INFO("performing buffered log\n");
    return this->DataLoggerQueue::Write(qbd);
  }

  //otherwise, write directly to the database
  else
  {
    //PRINT_INFO("performing non-buffered log\n");

    //sanity checks
    if (this->threadRunning)
    {
      PRINT_ERROR("cannot log while in threaded mode\n");
      return -1;
    }

    if (!this->loggerOpen)
    {
      PRINT_ERROR("log file is not open\n");
      return -1;
    }

    if (this->WriteDb(qbd))
    {
      PRINT_ERROR("could not write to Db\n");
      return -1;
    }

    //if we did not get values for a while, flush the buffer to file
    if (Upenn::Timer::GetAbsoluteTime() - lastSaved > this->flushPeriod)
    {
      PRINT_INFO("syncing log\n");

      if (this->Flush())
      
      {
	      PRINT_ERROR("could not sync log\n");
	      return -1;
      } 

      lastSaved = Upenn::Timer::GetAbsoluteTime();
    }
  }
  
  return 0;
}

int DataLoggerQueueDB::LogOneEntry()
{
  return 0;
}

int DataLoggerQueueDB::UpdateFunction()
{
  static double lastSaved = Upenn::Timer::GetAbsoluteTime();
  double timeout = 0.1;

  if (!this->pqBuf)
  {
    PRINT_ERROR("the buffer is NULL\n");
    return -1;
  }

  QBData qbd;

  int ret = this->pqBuf->Pop(&qbd,timeout);

  if (ret == 0)
  {
    this->SetBusy(true);
    if (this->WriteDb(&qbd))
    {
      this->pqBuf->PushDone(&qbd);
      PRINT_ERROR("could not write to db\n");
      return -1;
    }

    this->pqBuf->PushDone(&qbd);
  }

  //if we did not get values for a while, flush the buffer to file
  if (Upenn::Timer::GetAbsoluteTime() - lastSaved > this->flushPeriod)
  {
    //PRINT_INFO("syncing log\n");

    if (this->Flush())
    
    {
	    PRINT_ERROR("could not sync log\n");
	    return -1;
    } 

    //PRINT_INFO("done syncing log\n");

    lastSaved = Upenn::Timer::GetAbsoluteTime();
    this->SetBusy(false);
  }

  return 0;
}


int DataLoggerQueueDB::Flush()
{
  if (this->FlushDb())
  {
    PRINT_ERROR("could not flush db\n");
    return -1;
  }
  
  return 0;
}

int DataLoggerQueueDB::SetFlushPeriod(double period)
{
  if (period <= 0)
  {
    PRINT_ERROR("flush period must be non-negative\n");
    return -1;
  }

  if (this->threadRunning)
  {
    PRINT_ERROR("can only be called before Open()\n");
    return -1;
  }

  this->flushPeriod = period;
  return 0;
}

int DataLoggerQueueDB::GetDone(list<QBData> & done)
{
  if (this->pqBuf->GetDone(done))
  {
    PRINT_ERROR("could not get used pointers\n");
    return -1;
  }
  return 0;
}

