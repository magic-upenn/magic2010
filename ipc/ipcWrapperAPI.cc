/* 
  status = ipcAPI(args);

  Matlab Unix MEX file for interfacing to IPC 3.8.5, which can be
  found here: http://www.cs.cmu.edu/afs/cs/project/TCA/www/ipc/index.html

  compile with:
  mex -O ipcAPI.cc -lipc

  Alex Kushleyev
  University of Pennsylvania
  December, 2008
  akushley (at) seas (dot) upenn (dot) edu

  Thanks to Dr. Daniel D. Lee (the structure of code is based
  on his spreadAPI interface)
*/

#include "mex.h"
#include "IpcWrapper.hh"
#include <string>
#include "string.h"
#include <set>
#include <list>
#include <unistd.h>
#include <iostream>
#include <sys/time.h>
//#include <sys/types.h>

#define MAX_HOSTNAME_LENGTH 128
#define MAX_MSG_LENGTH 1024
#define MAX_FMT_LENGTH 1024
#define MAX_PID_LENGTH 128

//#define IPC_API_DEBUG

using namespace std;


struct MSG_INFO
{
  MSG_INFO(string _name,unsigned int _n_bytes,BYTE_ARRAY _ipc_data_ptr) : 
    name(_name), n_bytes(_n_bytes), ipc_data_ptr(_ipc_data_ptr) {}
  string name;
  unsigned int n_bytes;
  BYTE_ARRAY ipc_data_ptr;
};

//keep track whether we are connected to IPC
static bool connected=false;
static bool start = false;

//queue that stores the vectors of pointers to received data for each message type
list<MSG_INFO> ipc_messages;


struct ltstr
{
  bool operator()(string s1, string s2) const
  {
    return s1.compare(s2) < 0;
  }
};

set<string,ltstr> subscribed_message_names;

//function handle for the message. It simply fills in the data into the members of this class
void static MsgHandler(MSG_INSTANCE msg_inst, BYTE_ARRAY ipc_data_ptr, void * nothing)
{
  const char * msg_name = IPC_msgInstanceName(msg_inst);
  unsigned int msg_length = IPC_dataLength(msg_inst);
  ipc_messages.push_back(MSG_INFO(string(msg_name),msg_length,ipc_data_ptr));
#ifdef IPC_API_DEBUG
  printf("ipcAPI: Received a message of type '%s' with length %d\n",msg_name,msg_length); 
#endif
  //printf("."); fflush(stdout);
}

//function handle for the message. It simply fills in the data into the members of this class
void static StartMsgHandler(MSG_INSTANCE msg_inst, BYTE_ARRAY ipc_data_ptr, void * nothing)
{
  start=true;
}

void FlushLocalQueue()
{
  int n_msg = ipc_messages.size();
#ifdef IPC_API_DEBUG
  printf("ipcAPI: flush_local_queue: trying to flush local queue of size = %d\n",n_msg);
#endif
  for (int i=0; i<n_msg; i++)
  {
    MSG_INFO * message = &(ipc_messages.front());
   
    //free IPC memory
    IPC_freeByteArray(message->ipc_data_ptr);

#ifdef IPC_API_DEBUG
    printf("ipcAPI: flush_local_queue: flushed a message of type %s\n",message->name.c_str());
#endif

    //pop the message that just has been extracted
    ipc_messages.pop_front();
  }
}

void mexExit(void)
{
	printf("Exiting ipcAPI\n"); fflush(stdout);
	IpcWrapperDisconnect();
  FlushLocalQueue();
  subscribed_message_names.clear();
  connected=false;
}

//convert the messages to matlab data structures
void ProcessMessages(mxArray ** plhs)
{
  //if there are no messages, return empty matrix
  if (ipc_messages.empty())
  {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  //if there are messages, return all of them starting from the oldest one
  const char * fields[]= {"name","data"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  int n_messages = ipc_messages.size();
  plhs[0] = mxCreateStructMatrix(n_messages,1,nfields,fields);

  for (int m=0; m < n_messages; m++)
  {
    MSG_INFO * message = &(ipc_messages.front());
    mxSetField(plhs[0],m,"name",mxCreateString(message->name.c_str()));

    //allocate memory for the message payload
    int dims[2];
    dims[0] = 1;
    dims[1] = message->n_bytes;
    mxArray * messArray = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);

    //copy data from IPC buffer to output array to matlab    
    memcpy((char *)mxGetPr(messArray), message->ipc_data_ptr, message->n_bytes);
    mxSetField(plhs[0],m,"data",messArray);

    //free IPC memory
    IpcWrapperFreeByteArray(message->ipc_data_ptr);

    //pop the message that just has been extracted
    ipc_messages.pop_front();
  }

}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int BUFLEN = 256;
  char command[BUFLEN];	

  if (mxGetString(prhs[0], command, BUFLEN) != 0)
    mexErrMsgTxt("ipcAPI: Could not read string. (1st argument)");


  //connect to the ipc server. If the hostname is not provided as the
  //second argument, localhost connection to localhost will be attempted
  if (strcasecmp(command, "connect") == 0)
  {
    if (connected)
    {
      printf("ipcAPI: already connected\n");
      plhs[0]=mxCreateDoubleScalar(0);
      return;
    }

    //get the hostname of this machine
    //the process name will be "hostname_ipcAPI"
    //this is to tell ipc which process is sending messages (for logging purposes)
    char hostname[MAX_HOSTNAME_LENGTH];
    int got_host_name = gethostname(hostname,MAX_HOSTNAME_LENGTH);
    string process_name;

    char pid[MAX_PID_LENGTH];
    snprintf(pid,MAX_PID_LENGTH,"%d",(int)getpid());

    char nrand[MAX_PID_LENGTH];
    struct timeval currTime;
    gettimeofday(&currTime,NULL);
    snprintf(nrand,MAX_PID_LENGTH,"%d",currTime.tv_usec);
  
   
    char central_hostname[BUFLEN] = "localhost";

    //check if central host address is provided
    if (nrhs > 1)
    {
      if (mxGetString(prhs[1], central_hostname, BUFLEN) != 0)
        mexErrMsgTxt("ipcAPI: connect: Could not read string (hostname of central).");
    }

    //check if custom process name suffix is provided (for running several ipcWrapperAPI instances from same matlab instance)
    //otherwise a random number will be appended to avoid duplicate ipc clients
    if (nrhs > 2)
    {
      snprintf(nrand,MAX_PID_LENGTH,"%d",(int)mxGetPr(prhs[2])[0]);
    }

    if (got_host_name == 0)
      process_name = string("(") + string(hostname) + string(")-ipcWrapperAPI-") + string(pid) + "-" + string(nrand);
    else
      process_name = string("(") + string("unknown_host") + string(")-ipcWrapperAPI-") + string(pid) + "-" + string(nrand);


    if (IpcWrapperConnect(process_name,central_hostname))
        mexErrMsgTxt("ipcAPI: connect: could not connect to central.");

    connected=true;

    //set the atExit function
		mexAtExit(mexExit);

    plhs[0]=mxCreateDoubleScalar(1);
    return;
	}

  //disconnect from the ipc server
  if (strcasecmp(command, "disconnect") == 0)
  {
    FlushLocalQueue();
	  IpcWrapperDisconnect();
    subscribed_message_names.clear();
    connected = false;
    plhs[0] = mxCreateDoubleScalar(1);
  }

  //Define message of a particular type. All messages must be defined prior to sending
  //Only one process needs to define a message (across all the machines / processes)
  //Arguments: msg_name (string)
  else if (strcasecmp(command, "define") == 0)
  {
    if (nrhs < 2)
      mexErrMsgTxt("ipcAPI: define: please provide message name as the second argument");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: define: Could not read message name. (2nd argument)");

    //get the optional format string
    char formatStringBuf[MAX_FMT_LENGTH];
    char * formatString = NULL;
    if (nrhs == 3)
    {
      if (mxGetString(prhs[2],formatStringBuf, MAX_FMT_LENGTH) != 0)
        mexErrMsgTxt("ipcAPI: Could not read format string. (2nd argument)");
      formatString = formatStringBuf;
    }

    //define a message type
	  if (IpcWrapperDefineMsg(msg_name, string(formatString == NULL ? "" : formatString))) //formt is NULL for raw data
      mexErrMsgTxt("ipcApi: define: Could not define ipc message type");

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  //Send message. This will send message to central server, which will eventually send
  //it out to all processes which are signed up to that message.
  //Message must be defined using "define_msg" command before sending
  //Arguments: msg_name (string), msg (arbitrary data)
  else if (strcasecmp(command, "publish") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: publish: not connected to ipc");

    //check number of arguments
    if (nrhs != 3)
      mexErrMsgTxt("ipcAPI: publish: not enough arguments: format=('publish','msg_name',msg)");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: publish: Could not read message name. (2st argument)");

    //get pointer to the data
    char * send_buff = (char *) mxGetPr(prhs[2]);

    //get number of chars to send
    unsigned int n_send = mxGetNumberOfElements(prhs[2]) * mxGetElementSize(prhs[2]);

    //publish message
    if (IpcWrapperPublish(msg_name,n_send, send_buff))
      mexErrMsgTxt("ipcAPI: publish: Error sending message");
    
#ifdef IPC_API_DEBUG
    printf("ipcAPI: publish: published message of type '%s'\n",msg_name);
#endif

    plhs[0]=mxCreateDoubleScalar(1);
    return;
  }


  else if (strcasecmp(command, "publishVC") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: publishVC: not connected to ipc");

    //check number of arguments
    if (nrhs != 3)
      mexErrMsgTxt("ipcAPI: publishVC: not enough arguments: format=('publishVC','msg_name',msg)");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: publishVC: Could not read message name. (2st argument)");

    //get pointer to the data
    char * send_buff = (char *) mxGetData(prhs[2]);

    //get number of chars to send
    unsigned int n_send = mxGetNumberOfElements(prhs[2]) * mxGetElementSize(prhs[2]);

    //publish message
    if (IpcWrapperPublishVC(msg_name, n_send, send_buff))
      mexErrMsgTxt("ipcAPI: publishVC: Error sending message");
    
#ifdef IPC_API_DEBUG
    printf("ipcAPI: publishVC: published message of type '%s'\n",msg_name);
#endif

    plhs[0]=mxCreateDoubleScalar(1);
    return;
  }


  else if (strcasecmp(command, "subscribe") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: subscribe: not connected to ipc");

    //check number of input arguments
    if (nrhs != 2)
       mexErrMsgTxt("ipcAPI: subscribe: not enough arguments: format=('subscribe','msg_name')");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: subscribe: Could not read message name. (2st argument)");

    if (subscribed_message_names.find(string(msg_name)) != subscribed_message_names.end())
    {
      cout<<"ipcAPI: subscribe: Warning: already subscribed to message type "<<msg_name<<endl;        
      plhs[0] = mxCreateDoubleScalar(1);
      return;
    }

    //subscribe to the message
    if (IpcWrapperSubscribe(msg_name,MsgHandler,NULL))
    {
      string err = string("ipcAPI: subscribe: could not subscribe to a message of type: ") + string(msg_name);
      mexErrMsgTxt(err.c_str());
    }

    subscribed_message_names.insert(string(msg_name));

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  else if (strcasecmp(command, "unsubscribe") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: unsubscribe: not connected to ipc");
 if (!connected)
      mexErrMsgTxt("ipcAPI: subscribe: not connected to ipc");
    //check number of input arguments
    if (nrhs != 2)
       mexErrMsgTxt("ipcAPI: unsubscribe: not enough arguments: format=('unsubscribe','msg_name')");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: unsubscribe: Could not read message name. (2st argument)");

    //unsubscribe from the message
    if (IpcWrapperUnsubscribe(msg_name,MsgHandler))
    {
      string err = string("ipcAPI: unsubscribe: could not unsubscribe from a message of type: ") + string(msg_name);
      mexErrMsgTxt(err.c_str());
    }

    //erase from the subscribed list
    set<string,ltstr>::iterator it = subscribed_message_names.find(string(msg_name));
    if ( it != subscribed_message_names.end())
    {
      subscribed_message_names.erase(it);
    }

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  //receive and return a message to matlab.
  else if (strcasecmp(command, "receive") == 0 || strcasecmp(command, "listen") == 0 ||
           strcasecmp(command, "listenClear") == 0 || strcasecmp(command, "listenWait") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: receive: not connected to ipc");
    
    //convert the messages to matlab data structures
    ProcessMessages(plhs);

    return;
  }
  
  //Set the maximum queue length for a particular message.
  //Oldest messages are discarded.
  //Arguments: msg_name (string), queue_length (non-negative integer)
  else if (strcasecmp(command, "set_msg_queue_length") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: set_msg_queue_length: not connected to ipc");
    
    //check the number of arguments
    if (nrhs != 3)
      mexErrMsgTxt("ipcAPI: set_msg_queue_length: not enough arguments: format=('set_msg_queue_length','msg_name',length)");

    //get message name
    char msg_name[MAX_MSG_LENGTH];
    if (mxGetString(prhs[1], msg_name, MAX_MSG_LENGTH) != 0)
      mexErrMsgTxt("ipcAPI: set_msg_queue_length: Could not read message name. (2st argument)");

    //get the queue length
    int queue_length = mxGetPr(prhs[2])[0];
    if (queue_length <= 0)
      mexErrMsgTxt("ipcAPI: set_msg_queue_length: invalid queue length");

    if (IpcWrapperSetMsgQueueLength(msg_name,queue_length))
      mexErrMsgTxt("ipcAPI: set_msg_queue_length: could not set queue length");

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  //arguments: capacity (non-negative integer)
  else if (strcasecmp(command, "flush_local_queue") == 0)
  {
    if (!connected)
      mexErrMsgTxt("ipcAPI: flush_local_queue: not connected to ipc");
    
    FlushLocalQueue();
  
    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  else
    mexErrMsgTxt("ipcAPI: command not recognized");

  return;
}
