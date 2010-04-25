#ifndef IPC_LOGGER_DB_HH
#define IPC_LOGGER_DB_HH

#include "DataLoggerQueueDB.hh"
#include "PointerQueueBuffer.hh"
#include "XMLConfig.hh"
#include "Timer.hh"
#include <string>
#include <vector>
#include <ipc.h>

#define IPC_LOGGER_DB_DEF_FLUSH_PERIOD 2.0

using namespace std;

namespace Upenn
{

  //class for logging incoming IPC messages
  class IpcLoggerDB
  {
    //constructor
    public: IpcLoggerDB();
    
    //destructor
    public: ~IpcLoggerDB();
    
    //connect to the ipc central
    public: int Connect(string centralHost);

    //initialize the logger: read message types from xml, subscribe to them
    //and open the log files
    public: int Initialize(string xmlFileName, string logFileName);

    //receive messages for a give duration
    public: int Receive(int timeoutMs);
    
    //write to the logger (database)
    protected: int Write(QBData * qbd);


    //instance of the logger implementation
    protected: DataLoggerQueueDB * logger;
    
    //entity for parsing xml files
    protected: gazebo::XMLConfig * conf;
    
    //specifies whether we have initialized the required structures
    protected: bool initialized;
    
    //specifies whether we are connected to IPC
    protected: bool connected;
    
    //list of message types that are being logged
    protected: vector<string> msgTypes;
    
    //handler for receiving IPC messages to be logged
    protected: static void MsgHandler(MSG_INSTANCE msgInst,
                                      BYTE_ARRAY ipcDataPtr,
                                      void * classInstPtr);
  };
}

#endif
