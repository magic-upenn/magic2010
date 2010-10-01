#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <mex.h>

#define MAXBUFLEN 65500

using namespace std;

int fd = -1;
sockaddr_in addr;
bool connected = false;


void Disconnect()
{
  if (connected)
  {
    close(fd);
  }
  connected = false;
}

void mexExit(void)
{
	printf("Exiting UdpSendAPI\n"); fflush(stdout);
  Disconnect();
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

    mexAtExit(mexExit);
    connected = true;
    plhs[0] = mxCreateDoubleScalar(1);
	  return;
  }
  else if (strcasecmp(command, "send") == 0) 
  {
    if (!connected) mexErrMsgTxt("not connected");
    if (nrhs != 2) mexErrMsgTxt("provide uint8 data as second argument");
    if (mxGetClassID(prhs[1]) != mxUINT8_CLASS) mexErrMsgTxt("data must be a uint8 array");

    uint8_t * data = (uint8_t*)mxGetData(prhs[1]);
    int size       = mxGetNumberOfElements(prhs[1]);

    if (size > MAXBUFLEN)
    {
      printf("UdpSendAPI: data size (%d) exceeds the maximum limit of %d\n",size,MAXBUFLEN);
      plhs[0] = mxCreateDoubleScalar(0);
	    return;
    }

    if (sendto(fd, data, size, 0,(struct sockaddr *) &addr, sizeof(addr)) < 0)
    {
      printf("UdpSendAPI: could not send data\n");
      plhs[0] = mxCreateDoubleScalar(0);
	    return;
    }
    plhs[0] = mxCreateDoubleScalar(1);
	  return;
  }
  else
    mexErrMsgTxt("unknown command");
}


