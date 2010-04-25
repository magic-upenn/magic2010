#include "IpcLoggerDB.hh"
#include "ErrorMessage.hh"
#include "GazeboError.hh"
#include "IpcHelper.hh"
#include <list>
#include <sstream>

using namespace Upenn;
using namespace std;


///////////////////////////////////////////////////////////////////
// Constructor
IpcLoggerDB::IpcLoggerDB()
{
  this->logger                  = NULL;
  this->conf                    = NULL;
  this->initialized             = false;
  //this->logFormatter            = NULL;
}

///////////////////////////////////////////////////////////////////
// Destructor
IpcLoggerDB::~IpcLoggerDB()
{
  if (this->logger) delete this->logger;
  if (this->conf)   delete this->conf;
}

///////////////////////////////////////////////////////////////////
// Connect to the IPC server
int IpcLoggerDB::Connect(string centralHost)
{
  if (IPC_setVerbosity(IPC_Print_Errors) != IPC_OK)
  {
    PRINT_ERROR("could not set ipc verbosity mode\n");
    return -1;
  }

  if (IPC_isConnected())
    return 0;

  //get a unique process name
  string processName = IpcHelper::GetProcessName("IpcLoggerDB");

  if (IPC_connectModule(processName.c_str(),centralHost.c_str()) != IPC_OK)
  {
    PRINT_ERROR("could not connect to ipc central\n");
    return -1;
  }

  return 0;
}

///////////////////////////////////////////////////////////////////
// Handler for receiving serialized IPC messages
void IpcLoggerDB::MsgHandler(MSG_INSTANCE msgInst,
                            BYTE_ARRAY ipcDataPtr,
                            void * classInstPtr)
{
  //get timestamp
  double timestamp = Timer::GetAbsoluteTime();
  
  //get a pointer to this instance
  IpcLoggerDB * ipcLogger = (IpcLoggerDB *)classInstPtr; 

  //extract the message name
  const char * msgName = IPC_msgInstanceName(msgInst);

  //extract the message size
  unsigned int msgLen  = IPC_dataLength(msgInst);

  //make sure that logger is initialized
  if (!ipcLogger->logger)
  {
    PRINT_ERROR("logger is null");
    return;
  }

  QBData qbd;
  qbd.data      = (char*)ipcDataPtr;
  qbd.size      = msgLen;
  qbd.timestamp = timestamp;
  qbd.info      = strdup((char*)msgName);

  //write the data to the logger
  if (ipcLogger->Write(&qbd))
  {
    PRINT_ERROR("could not write to logger\n");
    return;
  }
  printf(".");
  //PRINT_INFO("pushed message of type "<< msgName <<" to the logger \n");
  
  //dont free the IPC data buffer here, since it will be used for
  //logging. Freeing will be done inside Write method after 
  //making sure that the data has been logged
  
  return;
}

///////////////////////////////////////////////////////////////////
// Load and parse xml file, subscribe to requested messages
int IpcLoggerDB::Initialize(string xmlFileName, string logFileName)
{

  //initial error checking
  if (this->initialized)
  {
    PRINT_ERROR("already initialized\n");
    return -1;
  }

  if (xmlFileName.empty())
  {
    PRINT_ERROR("xml file name must be non-empty\n");
    return -1;
  }

  if (logFileName.empty())
  {
    PRINT_ERROR("log file name must be non-empty\n");
    return -1;
  }

  //create a buffered logger
  this->logger   = new DataLoggerQueueDB();
  
  //make sure that the logger was allocated
  if (!this->logger)
  {
    PRINT_ERROR("could not create logger\n");
    return -1;
  }

  //initialze and load the configuration
  this->conf = new gazebo::XMLConfig();
  if (!this->conf)
  {
    PRINT_ERROR("could not create xml config\n");
    return -1;
  }

  stringstream logHeaderStream;
  logHeaderStream<<"CREATOR IpcLoggerDB"<<"\n";

  try
  {
    this->conf->Load(xmlFileName);
  
    //load the configuration from xml
    gazebo::XMLConfigNode * node = this->conf->GetRootNode();
    
    //get the first msgType xml node
    gazebo::XMLConfigNode * msgTypeNode = node->GetChild("msgType");
    
    //iterate over all msgType xml nodes
    while(msgTypeNode)
    {
      string type = msgTypeNode->GetValue();
      if (type.empty())
      {
        PRINT_WARNING("empty msgType");
        continue;
      }

      PRINT_INFO("adding type "<<type<<" to the list of messages to log\n");
      logHeaderStream<<"MSG_TYPE "<<type<<"\n";
    
      //store the message type in the array
      this->msgTypes.push_back(type);
      
      //get the next child
      msgTypeNode = msgTypeNode->GetNext("msgType");
    }

    //set the flush period for
    double flushPeriod = node->GetDouble("flushPeriod",IPC_LOGGER_DB_DEF_FLUSH_PERIOD,0);
    if (this->logger->SetFlushPeriod(flushPeriod))
    {
      PRINT_ERROR("could not set flush period\n");
      return -1;
    }
  }
  
  catch (gazebo::GazeboError e) 
  {
    PRINT_ERROR("error loading message types from xml file: "<<e<<"\n");
    return -1;
  }

  //initialize the logger
  if (this->logger->Open(logFileName,logHeaderStream.str()))
  {
    PRINT_ERROR("could not open the log file for writing\n");
    return -1;
  }
  
  //subscribe to the desired ipc messages
  int nTypes = this->msgTypes.size();
  for (int ii=0; ii<nTypes; ii++)
  {
    if (IPC_subscribe(this->msgTypes[ii].c_str(),this->MsgHandler,this) != IPC_OK)
    {
      PRINT_ERROR("could not subscribe to message : " <<this->msgTypes[ii]<<"\n");
      return -1;
    }
  }
  
  this->initialized = true;

  return 0;
}

///////////////////////////////////////////////////////////////////
// High-level function for logging data
int IpcLoggerDB::Write(QBData * qbd)
{

  //make sure we are initialized
  if (!this->initialized)
  {
    PRINT_ERROR("not initialized\n");
    return -1;
  }
  
  //write to logger
  if (this->logger->Write(qbd))
  {
    PRINT_ERROR("could not write to the logger");
    return -1;
  }

  //PRINT_INFO(qbd->info<<"\n");

  //get a list of QBData that has been logged
  list<QBData> usedData;
  if (this->logger->GetDone(usedData))
  {
    PRINT_ERROR("could not get used pointers\n");
    return -1;
  }

  //free the pointers that have been logged
  while(!usedData.empty())
  {
    IPC_freeByteArray(usedData.front().data);
    free(usedData.front().info);
    usedData.pop_front();
    //PRINT_INFO("freed array\n");
  }
  
  //PRINT_INFO("logged message of type "<<qbd->info<<"\n");

  return 0;
}


//receive and process IPC messages for a requested time period
int IpcLoggerDB::Receive(int timeoutMs)
{
  if (timeoutMs < 0)
  {
    PRINT_ERROR("timeout must be non-negative\n");
    return -1;
  }

  //just like usleep, but also processes messages
  IPC_listenWait(timeoutMs);

  return 0;
}
