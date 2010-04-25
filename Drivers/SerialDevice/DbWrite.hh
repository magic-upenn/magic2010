#ifndef DB_WRITE_HH
#define DB_WRITE_HH

#include <db_cxx.h>
#include "Timer.hh"
#include <fstream>
#include "PointerQueueBuffer.hh"

#define DB_WRITE_DEF_PAGE_SIZE 32*1024
#define DB_WRITE_DEF_CACHE_SIZE 1024*1024

namespace Upenn
{
  class DbWrite
  {

    //constructor
    public: DbWrite();

    //destructor
    public: ~DbWrite();

    //open the file for writing
    public:  int OpenDb(string filename, string header = string(""));

    //write data to the output file
    public: int WriteDb(QBData * qbd);

    public: int CloseDb();

    public: bool IsOpenDb();

    public: int FlushDb();
    
    protected: Db * db;
    protected: bool dbOpen;
    protected: Timer fileFlushTimer;
    protected: ofstream infoStream;
    protected: ofstream headStream;
    protected: double startTime;
    private: int cntr;
  };
}
#endif  //DB_WRITE_HH
