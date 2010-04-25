#include "DbWrite.hh"
#include "ErrorMessage.hh"
#include "DataLogger.hh"
#include "Timer.hh"
#include <time.h>

using namespace std;
using namespace Upenn;


DbWrite::DbWrite()
{
  this->db         = NULL;
  this->dbOpen     = false;
  this->startTime  = 0;
  this->cntr       = 0;
}

DbWrite::~DbWrite()
{
  this->CloseDb();
  if (this->db)         delete this->db;
}

bool DbWrite::IsOpenDb()
{
  return this->dbOpen;
}

int DbWrite::OpenDb(string filename, string header)
{
  string filenameDb   = filename + DATA_LOGGER_LOG_EXT;
  string filenameTime = filename + DATA_LOGGER_INFO_EXT;
  string filenameHead = filename + DATA_LOGGER_HEAD_EXT;

  remove(filenameDb.c_str());
  remove(filenameTime.c_str());
  remove(filenameHead.c_str());

  this->db = new Db(0,0);
  if (this->db == NULL)
  {
    PRINT_ERROR("could not create an instance of Db\n");
    return -1;
  }

  try
  {
    //set the error stream
    this->db->set_error_stream(&cerr);

    //set the error prefix
    this->db->set_errpfx("DataLoggerCirularDB");
    
    //set the page size
    this->db->set_pagesize(DB_WRITE_DEF_PAGE_SIZE);

    //set cache size
    this->db->set_cachesize(0,DB_WRITE_DEF_CACHE_SIZE,0);

    //open the database
    this->db->open(NULL,filenameDb.c_str(),NULL,DB_RECNO, DB_CREATE, 0664);
  }

  catch (DbException &dbe) 
  {
		PRINT_ERROR(dbe.what() << "\n");
		return -1;
	}


  this->infoStream.open(filenameTime.c_str(), ios::out);
  if( this->infoStream.fail() )
  {
    PRINT_ERROR("error opening output info file\n");
    return -1;
  }
  
  this->headStream.open(filenameHead.c_str(), ios::out);
  if( this->headStream.fail() )
  {
    PRINT_ERROR("error opening output header file\n");
    return -1;
  }

  this->infoStream.precision(6);
  this->infoStream<< fixed;
  this->headStream.precision(6);
  this->headStream<< fixed;

  this->startTime = Upenn::Timer::GetAbsoluteTime();

  time_t rawtime = (time_t)this->startTime;
  char * timeStr = asctime(gmtime(&rawtime));
  timeStr[strlen(timeStr)-1] = 0;

  //log the human readable starting time
  this->headStream<<"START_TIME_STRING "<<timeStr<<"\n";

  //log the exact starting time
  this->headStream<<"START_TIME_DOUBLE "<<this->startTime<<"\n";
  this->infoStream<<this->startTime<<"\n";

  //write the header if present
  if (!header.empty())
    this->headStream<<header<<"\n";
    
    
  //flush and close the header stream, since we won't need it any more
  this->headStream.flush();
  this->headStream.close();

  this->fileFlushTimer.Tic();

  this->dbOpen = true;

  return 0;
}

int DbWrite::WriteDb(QBData * qbd)
{
  if (!this->db)
  {
    PRINT_ERROR("the db is NULL\n");
    return -1;
  }

  if (!this->dbOpen)
  {
    PRINT_ERROR("the database is not open\n");
    return -1;
  }

  //write data to database
  //PRINT_INFO("about to write "<<numBytes<<"b to database\n");
  try
  {
    Dbt key;
    Dbt data((void*)qbd->data,qbd->size);

    memset(&key,0,sizeof(DBT));
    this->db->put(NULL,&key, &data, DB_APPEND);
  }
  catch (DbException &dbe) 
  {
	  PRINT_ERROR(dbe.what() << "\n");
	  return -1;
  }

  //store the timestamp
  this->cntr++;
  this->infoStream<<this->cntr<<" "<<(qbd->timestamp-this->startTime);
  if (qbd->info)
    this->infoStream<<" "<<qbd->info;
  this->infoStream<<"\n";

  //PRINT_INFO(qbd->info<<"\n");

  if( this->infoStream.fail() )
  {
    PRINT_ERROR("error while writing timestamp\n");
    return -1;
  }

  return 0;
}

int DbWrite::CloseDb()
{
  if (!this->dbOpen)
    return 0;

  PRINT_INFO("closing database\n");

  if ( this->db )
  {
    try
    {
      this->db->close(0);
    }
    catch (DbException &dbe) 
    {
	    PRINT_WARNING(dbe.what() << "\n");
    }
  }

  this->infoStream.close();

  this->dbOpen = false;
  return 0;
}

int DbWrite::FlushDb()
{
  try
  {
    this->db->sync(0);
  }
  catch (DbException &dbe) 
  {
    PRINT_ERROR(dbe.what() << "\n");
    return -1;
  }

  //flush the buffer and check for errors
  this->infoStream.flush();
  if( this->infoStream.fail() )
  {
    PRINT_ERROR("error while flushing the timestamp buffer\n");
    return -1;
  }

  return 0;
}
