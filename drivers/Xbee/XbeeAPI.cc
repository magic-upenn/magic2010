#include <mex.h>
#include <pthread.h>
#include <signal.h>
#include <iostream>
#include "Xbee.hh"
#include "XbeeFrame.h"
#include "DynamixelPacket.h"
#include <stdint.h>
#include "MagicMicroCom.h"
#include <list>
#include <vector>

#define MAX_QUEUE_LENGTH 100

using namespace std;
using namespace Upenn;

pthread_t xbeeThread;
pthread_mutex_t xbeeMutex = PTHREAD_MUTEX_INITIALIZER;
Xbee xbee;
bool connected     = false;
bool threadRunning = false;
int maxQueueLength = MAX_QUEUE_LENGTH;

struct XbeePacket
{
  XbeePacket() {}
  XbeePacket(int _src, int _rssi, uint8_t * _data, int size)
  {
    src = _src;
    rssi  = _rssi;
    data.resize(size);
    memcpy(&(data[0]),_data,size);
  }
  int src;
  int rssi;
  vector<uint8_t> data;
};

list<XbeePacket> packets;

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

  XbeeFrame frame;
  XbeeFrameInit(&frame);

  while(1)
  {
    pthread_testcancel();
    int len = xbee.ReceivePacket(&frame,0.1);
  
    if (len < 1)
      continue;

    int size = len - XBEE_FRAME_RX_OVERHEAD;

    uint8_t apiId = XbeeFrameGetApiId(&frame); 
    printf("got frame of size %d of type %x\n",size,apiId);

    if (apiId == XBEE_API_RX_PACKET_16)
    {
      uint16_t src = (frame.buffer[4]<<8) + frame.buffer[5];
      int rssi = frame.buffer[6];
      pthread_mutex_lock(&xbeeMutex);
      packets.push_back(XbeePacket(src,rssi,frame.buffer+XBEE_FRAME_OFFSET_PAYLOAD,size));
      
      while (packets.size() > maxQueueLength)
        packets.pop_front();

      pthread_mutex_unlock(&xbeeMutex);

      printf("src = %x, rssi = %d\n",src,-rssi);
    }
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
    {pthread_mutex_unlock(&xbeeMutex);
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
  else if (strcasecmp(command, "receive") == 0)
  {
    const char * fields[]= {"src","rssi","data"};
    const int nfields = sizeof(fields)/sizeof(*fields);

    pthread_mutex_lock(&xbeeMutex);
    int size = packets.size();
    plhs[0] = mxCreateStructMatrix(size,1,nfields,fields);
    
    for (int ii = 0; ii < size; ii++)
    {
      XbeePacket * packet = &(packets.front());
      mxSetField(plhs[0],ii,"src",mxCreateDoubleScalar(packet->src));
      mxSetField(plhs[0],ii,"rssi",mxCreateDoubleScalar(packet->rssi));

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
    pthread_mutex_unlock(&xbeeMutex);
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





