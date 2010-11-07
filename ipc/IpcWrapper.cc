#include "IpcWrapper.hh"
#include "IpcHelper.hh"
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <string>
#include "Timer.hh"
#include <list>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#define __IPC_WRAPPER_GET_SEND_LOCK_RETRIES 3

using namespace std;
using namespace Upenn;

bool __ipcWrapperThreadRunning = false;
bool __ipcWrapperConnected     = false;
pthread_t __ipcWrapperThread;
pthread_mutex_t __ipcWrapperActionRequestMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t __ipcWrapperActionMutex        = PTHREAD_MUTEX_INITIALIZER;

pthread_cond_t  __ipcWrapperActionCond  = PTHREAD_COND_INITIALIZER;
//pthread_cond_t  __ipcWrapperSendCond     = PTHREAD_COND_INITIALIZER;

int __ipcWrapperNumPendingActions = 0;
int __ipcWrapperSleepUs = 100;

Upenn::Timer __ipcTimer;

struct IpcPublishQueueEntry
{
  string msgName;
  bool freeManual;
  int size;
  uint8_t * data;
  
  IpcPublishQueueEntry(): freeManual(false),size(0),data(0) {}
  IpcPublishQueueEntry(string _msgName, bool _freeManual,int _size,uint8_t * _data) :
    msgName(_msgName),freeManual(_freeManual),size(_size),data(_data) {}
};

std::list<IpcPublishQueueEntry> __publishQueue;
std::list<IpcPublishQueueEntry> __publishVCQueue;

std::list<uint8_t*> __freeRawQueue;

int __IpcWrapperCheckPendingActions()
{
  int nActions;
  int ret;
  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  nActions = __ipcWrapperNumPendingActions;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -2;

  return nActions;
}

void *__IpcWrapperThreadFunc(void * input)
{
  int ret;

  sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  ret = pthread_mutex_lock( &__ipcWrapperActionMutex );

  while(true)
  {
    //see if we need to cancel the thread		
    pthread_testcancel();

    int nPendingActions = __IpcWrapperCheckPendingActions();

    while (nPendingActions > 0)
    {
      //wait until all the pending actions are executed
      ret = pthread_cond_wait(&__ipcWrapperActionCond,&__ipcWrapperActionMutex);

      //FIXME: what do we do if pthread_cond_wait fails and does not re-lock the mutex???

      //verify that the number of pending actions is actually zero,
      //since pthread_cond_wait can wake up on its own
      nPendingActions = __IpcWrapperCheckPendingActions();
    }

    __ipcTimer.Tic();
    //printf("?"); fflush(stdout);
    
    //try to receive messages
    int ret = IPC_listenWait(10);
    
    switch (ret)
    {
      case IPC_OK:
        break;
      case IPC_Error:
        printf("not connected!\n");
      case IPC_Timeout:
        //printf("."); fflush(stdout);
        break;
      default:
        break;
    }
    
    //printf("!"); fflush(stdout);
    
    
    bool empty = true;
    
    pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
    empty = __publishQueue.empty(); 
    pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    
    
    while(!empty)
    {
      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      IpcPublishQueueEntry & entry = __publishQueue.front();
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
      ret = IPC_publish(entry.msgName.c_str(),entry.size,entry.data);
      if (ret != IPC_OK)
        printf("could not publish ipc message\n");
        
      if (entry.freeManual)
        delete [] entry.data;
      
      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      __publishQueue.pop_front();
      empty = __publishQueue.empty(); 
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    }
    
    
    pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
    empty = __publishVCQueue.empty(); 
    pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    
    while(!empty)
    {
      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      IpcPublishQueueEntry & entry = __publishVCQueue.front();
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
      IPC_VARCONTENT_TYPE varcontent;
      varcontent.length  = entry.size;
      varcontent.content = entry.data;

      ret = IPC_publishVC(entry.msgName.c_str(), &varcontent);
      if (ret != IPC_OK)
        printf("could not publish ipc message\n");
        
      if (entry.freeManual)
        delete [] entry.data;
        
      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      __publishVCQueue.pop_front();
      empty = __publishVCQueue.empty(); 
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    }



    pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
    empty = __freeRawQueue.empty(); 
    pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    
    while(!empty)
    {
      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      uint8_t * entry = __freeRawQueue.front();
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );

      IPC_freeByteArray(entry);

      pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
      __freeRawQueue.pop_front();
      empty = __freeRawQueue.empty(); 
      pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
    }
    
    usleep(__ipcWrapperSleepUs);

    //double dt= __ipcTimer.Toc();
    //printf("ipc waited %f seconds \n",dt); fflush(stdout);
  }

  return NULL;
}

int __IpcWrapperStartThread()
{
  int ret;
  ret = pthread_create(&__ipcWrapperThread,NULL,__IpcWrapperThreadFunc, NULL);
  __ipcWrapperThreadRunning = true;
  return ret;
}


int __IpcWrapperGetActionLock()
{
  int ret;

  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  __ipcWrapperNumPendingActions++;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -2;

  ret = pthread_mutex_lock( &__ipcWrapperActionMutex );
  if (ret) return -3;
  else return 0;
}

int __IpcWrapperReleaseActionLock()
{
  int ret;

  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  __ipcWrapperNumPendingActions--;


  //signal that there are no more pending actions
  if (__ipcWrapperNumPendingActions == 0)
  {
    ret = pthread_cond_signal(&__ipcWrapperActionCond);
    if (ret) return -2;
  }

  ret = pthread_mutex_unlock( &__ipcWrapperActionMutex );
  if (ret) return -3;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -4;
  
  else return 0;
}



int IpcWrapperConnect(string taskName, 
                      string serverName,
                      bool multiThread)
{
  //check if already connected
  if (__ipcWrapperConnected)
    return 0;

  //set the verbosity to printing errors, so that ipc does not exit on errors
  IPC_setVerbosity(IPC_Print_Errors);

  
  //generate a unique process name and connect
  int ret = IPC_connectModule(IpcHelper::GetProcessName(taskName).c_str(), 
                              serverName.c_str());
  
  if (ret == IPC_OK)
  {
    printf("connected to ipc\n");
    
    IPC_disconnect();
    
    ret = IPC_connectModule(IpcHelper::GetProcessName(taskName).c_str(), 
                              serverName.c_str());

    if (multiThread)
    {
      ret = __IpcWrapperStartThread();
      if ( ret != 0) return -2;
      printf("started thread\n");
    }

    __ipcWrapperConnected = true;
    return 0;
  }
  else return -1;
}


bool IpcWrapperIsConnected()
{
 return __ipcWrapperConnected;
}

int IpcWrapperDisconnect()
{
  if (!__ipcWrapperConnected)
    return 0;


  //TODO: implement proper disconnect procedure
  
  pthread_cancel(__ipcWrapperThread);
  pthread_join(__ipcWrapperThread,NULL);
  printf("stopped thread\n");
  
  //IPC_disconnect();
  //printf("disconnected from ipc\n");

  return 0;
}



int IpcWrapperDefineMsg(string msgName, string formatString)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  char * fmt = NULL;
  if (!formatString.empty())
    fmt = (char*)formatString.c_str();

  int ret2 = IPC_defineMsg(msgName.c_str(), IPC_VARIABLE_LENGTH, fmt);

  ret = __IpcWrapperReleaseActionLock();
  
  if (ret) return -2;

  if (ret2 != IPC_OK) return 3;
  else return 0;
}



int IpcWrapperPublish(string msgName, unsigned int size,
                      void * data)
{
  uint8_t * tempData = new uint8_t[size];
  memcpy(tempData,data,size);
  
  pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  __publishQueue.push_back(IpcPublishQueueEntry(msgName,true,size,tempData));
  pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );

  return 0;
}

int IpcWrapperPublishData(string msgName, void * data)
{
  printf("PublishData is disabled\n");
  exit(1);
  
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_publishData(msgName.c_str(),data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperPublishVC(string msgName, unsigned int size, void * data)
{
  uint8_t * tempData = new uint8_t[size];
  printf("%d\n",size);
  if (tempData == NULL)
    printf("oh noes! %d\n",size);
  memcpy(tempData,data,size);

  pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  __publishVCQueue.push_back(IpcPublishQueueEntry(msgName,true,size,tempData));
  pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );

  return 0;
}


int IpcWrapperSubscribe(string msgName, HANDLER_TYPE handler,
                        void * clientData)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_subscribe(msgName.c_str(),handler,clientData);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperSubscribeData(string msgName, HANDLER_DATA_TYPE handler,
                        void * clientData)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_subscribeData(msgName.c_str(),handler,clientData);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperUnsubscribe(string msgName, HANDLER_TYPE handler)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_unsubscribe(msgName.c_str(),handler);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperQueryResponseData(const char * msgName, void * data,
                                void ** replyData, unsigned int timeoutMsecs)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_queryResponseData(msgName,data,replyData,timeoutMsecs);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}


int IpcWrapperFreeData(const char * format, void * data)
{


  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IpcWrapperFreeData(IPC_parseFormat(format),data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperFreeData(FORMATTER_PTR formatter, void * data)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_freeData(formatter,data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperFreeByteArray(void * data)
{
/*
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  IPC_freeByteArray(data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;
  else return 0;
*/

  pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  __freeRawQueue.push_back((uint8_t*)data);
  pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );

  return 0;
}

int IpcWrapperSetMsgQueueLength(string msgName, int length)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_setMsgQueueLength((char*)msgName.c_str(),length);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}


int IpcWrapperNumHandlers(string msgName)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_numHandlers((char*)msgName.c_str());

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  return ret2;
}

int IpcWrapperListenWait(int milliseconds)
{
  if (__ipcWrapperThreadRunning)
    return -1;

  int ret = IPC_listenWait(milliseconds);

  if (ret != IPC_OK)
    return -1;
  return 0;
}



