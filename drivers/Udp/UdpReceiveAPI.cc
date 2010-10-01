#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <mex.h>
#include <pthread.h>
#include <signal.h>
#include <list>
#include <vector>
#include <string>
#include <list>

using namespace std;

#define MAXBUFLEN 65500
char buf[MAXBUFLEN];

#define DEF_MAX_QUEUE_LENGTH 10

int fd = -1;
sockaddr_in addr;
bool connected     = false;
bool threadRunning = false;
int maxQueueLength    = DEF_MAX_QUEUE_LENGTH;

pthread_t udpThread;
pthread_mutex_t udpMutex = PTHREAD_MUTEX_INITIALIZER;

struct UdpPacket
{
  UdpPacket() {}
  UdpPacket(string _src, uint8_t * _data, int size)
  {
    src = string(_src);
    data.resize(size);
    memcpy(&(data[0]),_data,size);
  }
  string src;
  vector<uint8_t> data;
};

list<UdpPacket> packets;

void Disconnect()
{
  if (threadRunning)
  {
    printf("stopping thread..."); fflush(stdout);
    pthread_cancel(udpThread);
    pthread_join(udpThread,NULL);
    threadRunning = false;
    printf("done\n");
  }

  if (connected)
    close(fd);
  connected = false;
}


void mexExit(void)
{
	printf("Exiting UdpReceiveAPI\n"); fflush(stdout);
  Disconnect();
}


void * UdpReceiveThreadFunc(void * input)
{
  sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  while(1)
  {
    pthread_testcancel();
    int numbytes;
    sockaddr_in senderAddr;
    socklen_t addr_len = sizeof(struct sockaddr);
    if ((numbytes = recvfrom(fd, buf, MAXBUFLEN-1 , 0,
		  (struct sockaddr *)&senderAddr, &addr_len)) == -1)
    {
		  printf("error while receiving data\n");
		  continue;
	  }

/*
	  printf("got packet from %s\n",inet_ntoa(senderAddr.sin_addr));
	  printf("packet is %d bytes long\n",numbytes);
	  buf[numbytes] = '\0';
	  printf("packet contains \"%s\"\n",buf);
*/
    pthread_mutex_lock(&udpMutex);
    packets.push_back(UdpPacket(inet_ntoa(senderAddr.sin_addr),(uint8_t*)buf,numbytes));

    while (packets.size() > maxQueueLength)
      packets.pop_front();
    pthread_mutex_unlock(&udpMutex);
  }

  return NULL;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	// Get input arguments
	if (nrhs == 0)
		mexErrMsgTxt("Need input argument");
	
	const int BUFLEN = 256;
	char command[BUFLEN];

	if (mxGetString(prhs[0], command, BUFLEN) != 0)
		mexErrMsgTxt("Could not read string.");

	//parse the commands
	if (strcasecmp(command, "connect") == 0) 
  {
    if (connected)
    {
			plhs[0] = mxCreateDoubleScalar(1);
			return;
		}
    
    if (nrhs != 3) mexErrMsgTxt("Please enter correct arguments: 'connect', <address>, <port>\n");

		char address[BUFLEN];
		if (mxGetString(prhs[1], address, BUFLEN) != 0)
			mexErrMsgTxt("Could not read string while reading the address");

		int port=(int)mxGetPr(prhs[2])[0];

    if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
      mexErrMsgTxt("could not create a socked");

    memset(&addr,0,sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(address);
    addr.sin_port=htons(port);

    if (bind(fd, (struct sockaddr *)&addr,
		    sizeof(struct sockaddr)) == -1)
      mexErrMsgTxt("could not bind to socket");

    //start thread
    if (pthread_create(&udpThread,NULL,UdpReceiveThreadFunc, NULL))
      mexErrMsgTxt("Could not start thread");
    
    connected = true;
    threadRunning = true;

    mexAtExit(mexExit);
    connected = true;
    plhs[0] = mxCreateDoubleScalar(1);
	  return;
  }
  else if (strcasecmp(command, "receive") == 0)
  {
    const char * fields[]= {"src","data"};
    const int nfields = sizeof(fields)/sizeof(*fields);

    pthread_mutex_lock(&udpMutex);
    int size = packets.size();
    plhs[0] = mxCreateStructMatrix(size,1,nfields,fields);
    
    for (int ii = 0; ii < size; ii++)
    {
      UdpPacket * packet = &(packets.front());
      mxSetField(plhs[0],ii,"src",mxCreateString(packet->src.c_str()));

      int dataSize = packet->data.size();
      int dims[2];
      dims[0] = 1;
      dims[1] = dataSize;
      mxArray * dataArray = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);

      //copy data from IPC buffer to output array to matlab    
      memcpy((char *)mxGetPr(dataArray), &(packet->data[0]), dataSize);
      mxSetField(plhs[0],ii,"data",dataArray);
    
      packets.pop_front();
    }
    pthread_mutex_unlock(&udpMutex);
   
  }
  else if (strcasecmp(command, "setQueueLength") == 0)
  {
    if (nrhs != 2) mexErrMsgTxt("provide queue length as second argument");
    int newLen = (int)(mxGetPr(prhs[1])[0]);
    maxQueueLength = newLen;
  
    plhs[0] = mxCreateDoubleScalar(1);
	  return;
  }

  else
    mexErrMsgTxt("unknown command");
}



