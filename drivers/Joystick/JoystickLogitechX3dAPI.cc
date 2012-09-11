#include <mex.h>
#include <pthread.h>
#include <signal.h>
#include "Joystick.hh"
#include <iostream>

using namespace Upenn;
using namespace std;

pthread_t joyThread;
pthread_mutex_t joyMutex = PTHREAD_MUTEX_INITIALIZER;
Joystick joy;
bool connected     = false;
bool threadRunning = false;


int vCmd = 0;
int wCmd = 0;

void Disconnect()
{
  if (threadRunning)
  {
    printf("stopping thread..."); fflush(stdout);
    pthread_cancel(joyThread);
    pthread_join(joyThread,NULL);
    threadRunning = false;
    printf("done\n");
  }

  if (connected)
    joy.Disconnect();
  connected = false;
}

void mexExit(void)
{
	printf("Exiting JoystickLogitechX3API\n"); fflush(stdout);
  Disconnect();
}

void * JoyThreadFunc(void * input)
{
  sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  double timeout = 0.05;
  input_event ev;

  while(1)
  {
    pthread_testcancel();
    if (joy.Read(&ev,timeout) == 0)
    {
      if (ev.type == 3 && ev.code == 0)
        wCmd = 511-ev.value;
      if (ev.type == 3 && ev.code == 1)
        vCmd = 511-ev.value;

      printf("type = %d code = %d value %d\n",ev.type, ev.code, ev.value);
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
    {
      plhs[0] = mxCreateDoubleScalar(1);
      return;
    }

    //connect to the joystick device    
    if (nrhs != 2) mexErrMsgTxt("Please enter correct arguments: 'connect', <device>\n");

		char deviceName[BUFLEN];
		if (mxGetString(prhs[1], deviceName, BUFLEN) != 0)
			mexErrMsgTxt("Could not read string while reading the device name");


		//connect to the device and set IO mode (see SerialDevice.hh for modes)
		if (joy.Connect(deviceName))
	  	mexErrMsgTxt("Could not open device");


    //start thread
    if (pthread_create(&joyThread,NULL,JoyThreadFunc, NULL))
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
  else if (strcasecmp(command, "getCmd") == 0)
  {
    int v,w;

    //pthread_mutex_lock(&joyMutex);
    v = vCmd;
    w = wCmd;
    //pthread_mutex_unlock(&joyMutex);

    plhs[0] = mxCreateDoubleScalar(v);
    plhs[1] = mxCreateDoubleScalar(w);
    return;
  }
  else
    mexErrMsgTxt("unknown command\n");
}

