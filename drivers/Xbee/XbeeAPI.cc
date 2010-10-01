#include <mex.h>
#include <pthread.h>
#include <signal.h>
#include <iostream>
#include "Xbee.hh"
#include "XbeeFrame.h"
#include "DynamixelPacket.h"
#include <stdint.h>
#include "MagicMicroCom.h"

using namespace std;
using namespace Upenn;

pthread_t xbeeThread;
pthread_mutex_t xbeeMutex = PTHREAD_MUTEX_INITIALIZER;
Xbee xbee;
bool connected     = false;
bool threadRunning = false;



void Disconnect()
{
  if (threadRunning)
  {
    printf("stopping thread..."); fflush(stdout);
    pthread_cancel(xbeeThread);
    pthread_join(xbeeThread,NULL);
    threadRunning = false;
    printf("done\n");
  }

  if (connected)
    xbee.Disconnect();
  connected = false;
}

void mexExit(void)
{
	printf("Exiting xbeeAPI\n"); fflush(stdout);
  Disconnect();
}


void * XbeeThreadFunc(void * input)
{
  sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  while(1)
  {
    pthread_testcancel();
    //printf("."); fflush(stdout);
    usleep(100000);
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

		if (nrhs != 3) mexErrMsgTxt("Please enter correct arguments: 'connect', <device>, <baud rate>\n");

		char deviceName[BUFLEN];
		if (mxGetString(prhs[1], deviceName, BUFLEN) != 0)
			mexErrMsgTxt("Could not read string while reading the device name");

		int baud=(int)mxGetPr(prhs[2])[0];
		
    if (xbee.Connect(deviceName,baud))
	  	mexErrMsgTxt("Could not open device");


    //start thread
    if (pthread_create(&xbeeThread,NULL,XbeeThreadFunc, NULL))
      mexErrMsgTxt("Could not start thread");
    
    connected = true;
    threadRunning = true;
		
		//set the atExit function
		mexAtExit(mexExit);

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }

  else if (strcasecmp(command, "disconnect") == 0)
  {
    Disconnect();

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }
  else if (strcasecmp(command, "writeVelCmd") == 0)
  {
    const int bufSize = 256;
    uint8_t buf[bufSize];
    uint8_t * data = (uint8_t*)mxGetData(prhs[1]);
    int size       = mxGetNumberOfElements(prhs[1])*mxGetElementSize(prhs[1]);
    int packetSize = DynamixelPacketWrapData(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                       MMC_MOTOR_CONTROLLER_VELOCITY_SETTING,data,size,buf,bufSize);

    int addr = 0xFFFF;
    if (nrhs == 3)
      addr = (int)mxGetPr(prhs[2])[0];

    if (packetSize > 0)
    {
      if (xbee.WritePacket(buf,packetSize,addr))
      {
        printf("could not write xbee packet\n");
        plhs[0] = mxCreateDoubleScalar(0);
        return;
      }
    }
    else
    {
      printf("could not wrap xbee packet\n");
      plhs[0] = mxCreateDoubleScalar(0);
      return;
    }

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }
  else if (strcasecmp(command, "writeRobSelect") == 0)
  {
    if (nrhs != 2) mexErrMsgTxt("provide robot number as second argument");
    uint8_t id = (uint8_t)(mxGetPr(prhs[1])[0]);

    if (id > 10) mexErrMsgTxt("bad robot id");

    const int bufSize = 256;
    uint8_t buf[bufSize];

    int packetSize = DynamixelPacketWrapData(MMC_MASTER_DEVICE_ID,
                                             MMC_MASTER_ROBOT_SELECT,
                                             &id,sizeof(uint8_t),buf,bufSize);

    int addr = 0xFFFF;  //broadcast robot selection
    if (packetSize > 0)
    {
      if (xbee.WritePacket(buf,packetSize,addr))
      {
        printf("could not write xbee packet\n");
        plhs[0] = mxCreateDoubleScalar(0);
        return;
      }
    }
    else
    {
      printf("could not wrap xbee packet\n");
      plhs[0] = mxCreateDoubleScalar(0);
      return;
    }

    plhs[0] = mxCreateDoubleScalar(1);
    return;

  }
  else
    mexErrMsgTxt("unknown command\n");
}





