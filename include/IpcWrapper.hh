#ifndef IPC_WRAPPER_HH
#define IPC_WRAPPER_HH

#include <ipc.h>
#include <string>

using namespace std;

int IpcWrapperConnect(string taskName, 
                      string serverName = string("localhost"),
                      bool multiThread = true);

int IpcWrapperDefineMsg(string msgName, string formatString);

int IpcWrapperPublish(string msgName, unsigned int length,
                      BYTE_ARRAY content);

int IpcWrapperPublishData(string msgName, void * data);


int IpcWrapperSubscribe(string msgName, HANDLER_TYPE handler,
                        void * clientData);

int IpcWrapperSubscribeData(string msgName, HANDLER_DATA_TYPE handler,
                            void * clientData);

int IpcWrapperUnsubscribe(string msgName, HANDLER_TYPE handler);

int IpcWrapperQueryResponseData(const char * msgName, void * data,
                                void ** replyData, unsigned int timeoutMsecs);
                                
int IpcWrapperFreeData(const char * format, void * data);
int IpcWrapperFreeData(FORMATTER_PTR formatter, void * data);
int IpcWrapperFreeByteArray(void * data);

int IpcWrapperSetMsgQueueLength(string msgName, int length);

bool IpcWrapperIsConnected();

int IpcWrapperDisconnect();

int IpcWrapperNumHandlers(string msgName);

int IpcWrapperListenWait(int milliseconds);

#endif //IPC_WRAPPER_HH
