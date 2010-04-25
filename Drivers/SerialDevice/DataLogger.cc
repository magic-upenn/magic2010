#include "DataLogger.hh"

using namespace std;
using namespace Upenn;

DataLogger::DataLogger()
{
  this->busy       = false;
  this->loggerOpen = false;
  pthread_mutex_init( &(this->dataMutex) , NULL );
}

DataLogger::~DataLogger()
{
  pthread_mutex_destroy(&(this->dataMutex));
}

void DataLogger::LockDataMutex()
{
  pthread_mutex_lock( &this->dataMutex );
}

void DataLogger::UnlockDataMutex()
{
  pthread_mutex_unlock( &this->dataMutex );
}

bool DataLogger::IsBusy()
{
  bool b = false;
  this->LockDataMutex();
  b = this->busy;
  this->UnlockDataMutex();
  return b;
}

void DataLogger::SetBusy(bool b)
{
  this->LockDataMutex();
  this->busy = b;
  this->UnlockDataMutex();
}

