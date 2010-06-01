#include "DataPlaybackDB.hh"
#include "ErrorMessage.hh"
#include "DataLogger.hh"
#include "Timer.hh"
#include <math.h>

using namespace std;
using namespace Upenn;

DataPlaybackDB::DataPlaybackDB()
{
  this->db           = NULL;
  this->dbc          = NULL;
  this->dbcFirst     = NULL;
  this->dbcLast      = NULL;
  this->firstTime    = true;
  this->initSeekTime = -1;
}

DataPlaybackDB::~DataPlaybackDB()
{
  if (this->db) delete this->db;
}

ifstream & DataPlaybackDB::GetHeader()
{
  return this->headStream;
}

int DataPlaybackDB::Open(string filename)
{
  if (this->fileOpen)
  {
    PRINT_ERROR("files are already open\n");
    return -1;
  }

  if (filename.empty())
  {
    PRINT_ERROR("log name must be non-empty\n");
    return -1;
  }

  string filenameDb   = filename + DATA_LOGGER_LOG_EXT;
  string filenameTime = filename + DATA_LOGGER_INFO_EXT;
  string filenameHead = filename + DATA_LOGGER_HEAD_EXT;

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
    this->db->set_errpfx("DataPlaybackDB");
    
    //set the page size
    //this->db->set_pagesize(1024*32);

    //set cache size
    this->db->set_cachesize(0,128*1024,0);

    //open the database
    this->db->open(NULL,filenameDb.c_str(),NULL,DB_RECNO, DB_RDONLY, 0664);

    this->db->cursor(NULL,&(this->dbc), 0);

    Dbt key;
    Dbt data;
    this->db->cursor(NULL,&(this->dbcFirst),0);
    this->db->cursor(NULL,&(this->dbcLast),0);
    this->dbcFirst->get(&key,&data,DB_FIRST);
    this->dbcLast->get(&key,&data,DB_LAST);
  }

  catch (DbException &dbe) 
  {
		PRINT_ERROR(dbe.what() << "\n");
		return -1;
	}

  this->infoStream.open(filenameTime.c_str(), ios::in | ios::binary);
  if( this->infoStream.fail() )
  {
    PRINT_ERROR("error opening input info file\n");
    return -1;
  }
  
  this->headStream.open(filenameHead.c_str(), ios::in | ios::binary);
  if( this->headStream.fail() )
  {
    PRINT_ERROR("error opening input header file\n");
    return -1;
  }

  int cntr;
  string infoStr;
  double timestamp;

  //read the initial timestamp which is the unix time of log start
  this->infoStream >> timestamp;

  this->timestamps.push_back(timestamp);
  this->info.push_back(infoStr);

  //read in the timestamps from the file
  
  PRINT_INFO("reading log file...");
  
  
  int entryCntr=0;
  while(true)
  {
    entryCntr++;
    if (entryCntr % 1000 == 0)
      printf("."); fflush(stdout);
    
    this->infoStream >> cntr;
    this->infoStream >> timestamp;
    infoStr.erase();

    int nextChar = this->infoStream.peek();
    if (nextChar != '\n')
      this->infoStream >> infoStr;

    if (this->infoStream.eof())
      break;

    if( this->infoStream.fail() )
    {
      PRINT_ERROR("could not read a timestamp\n");
      break;
      return -1;
    }

    this->timestamps.push_back(timestamp);
    this->info.push_back(infoStr);
  }
  
  this->logStartTime  = this->timestamps[0];
  
  //FIXME: have an option of waiting for an IPC message here
  this->playStartTime = Timer::GetAbsoluteTime();
  
  PRINT_INFO("read "<<this->timestamps.size()<<" entries\n");

  this->fileOpen = true;

  return 0;
}

int DataPlaybackDB::Close()
{
  if (!this->fileOpen)
    return 0;

  if ( this->db )
  {
    PRINT_INFO("Closing the database\n");
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
  this->headStream.close();

  this->fileOpen = false;
  return 0;
}

double DataPlaybackDB::GetLogStartTime()
{
  if (this->fileOpen)
    return this->logStartTime;
  
  PRINT_ERROR("log is not initialized\n");
  return -1;
}

int DataPlaybackDB::GetData(char ** dataPtrPtr, int & dataLength, 
                            double & timestamp, string & infoStr, 
                            double seekTime)
{
  dataLength = 0;
  timestamp  = -1;
  infoStr.erase();

  Dbt key;
  Dbt data;

  int cmpResult;

  try
  {
    //if we are not seeking to another time, just go in order
    if (seekTime < 0)
    {
      switch(this->dir)
      {
        case 1:
          if (!this->firstTime)
          {
            this->dbc->cmp(this->dbcLast,&cmpResult,0);
            if (cmpResult == 0)
            {
              PRINT_WARNING("reached the end\n");
              return -2;
            }
          }
          this->dbc->get(&key,&data,DB_NEXT);
          break;
        case -1:
          if (!this->firstTime)
          {
            this->dbc->cmp(this->dbcFirst,&cmpResult,0);
            if (cmpResult == 0)
            {
              PRINT_WARNING("reached the start\n");
              return -2;
            }
          }
          this->dbc->get(&key,&data,DB_PREV);
          break;
        default:
          PRINT_ERROR("bad playback direction");
          return -1;
      }
    }
    else
    {
      if (firstTime)
      {
        if (seekTime == 0)
        {
          PRINT_ERROR("initial seek time cannot be zero\n");
          return -1;
        }
        else
          this->initSeekTime = seekTime;
      }
      
      if (seekTime ==0)
      {
        this->playStartTime = Timer::GetAbsoluteTime();
        seekTime = this->initSeekTime;
        this->lastLogTime = -1; 
      }
    
    
      //find the closest time stamp
      unsigned int nTimestamps = this->timestamps.size();
      double * pt = &(this->timestamps[1]);
      uint32_t recno;

      //timestamps start from index 1
      for (unsigned int ii=1; ii<nTimestamps; ii++)
      {
        if (dir > 0)
        {
          if (seekTime < (*pt+this->logStartTime))
          {
            recno = ii;
            break;
          }
        }
        else if (dir < 0)
        {
          if (seekTime > (*pt+this->logStartTime))
          {
            recno = ii-1;
            break;
          }
        }
        pt++;
      }

      //printf("recno = %d\n",recno);

      if (recno <= 1)
        this->dbc->get(&key, &data, DB_FIRST);
      else if (recno >= nTimestamps)
        this->dbc->get(&key, &data, DB_LAST);
      else
      {
        key.set_data(&recno);
        key.set_size(sizeof(uint32_t));

        this->dbc->get(&key,&data,DB_SET);
      }
    }
  }
  catch (DbException &dbe) 
  {
    int err = dbe.get_errno();
		PRINT_ERROR(dbe.what() <<" Error number ="<<err<< "\n");
		return -1;
	}

  firstTime = false;

  //check the bounds. recnos start with 1
  uint32_t recno = *(uint32_t*)key.get_data();
  if (recno >= this->timestamps.size())
  {
    PRINT_ERROR("recno is greater than the timestamp array length\n");
    return -1;
  }

  //record numbers start with 1 and so do timestamps
  double logTime = this->timestamps[recno];

  //PRINT_INFO("got recno "<<recno<<"\n");
  //printf("timestamp= %f\n",logTime);

  if (seekTime > 0)
  {
    this->playStartTime = Upenn::Timer::GetAbsoluteTime() + (this->logStartTime + logTime - seekTime);
  }

  if (this->lastLogTime < 0)
  {
    //TODO: this is the first time the value is returned. We may want
    //to set this to something that's globally set via IPC, so that the
    //playback is globally synchronized
    //this->playStartTime = Upenn::Timer::GetAbsoluteTime();
    

    timestamp = this->playStartTime - this->playOffset;
  }
  else
  {
    double dt         = logTime - this->lastLogTime;
    timestamp         = this->lastReturnedTime + this->logPausedTime + fabs(dt)/this->speed;
    
  }
  this->lastLogTime      = logTime;
  this->lastReturnedTime = timestamp;
  this->logPausedTime = 0;
  
  *dataPtrPtr = (char*)data.get_data();
  dataLength  = data.get_size();
  infoStr     = this->info[recno];
 
  return 0;
}
