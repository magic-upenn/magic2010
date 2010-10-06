/*
  x = darwinCam(args);

  Matlab 7.4 Linux MEX file
  to read from USB uvc camera.
  
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
*/

#include <string>
#include "v4l2.h"
#include "mex.h"

#define VIDEO_DEVICE "/dev/video0"

#define WIDTH 320
#define HEIGHT 240
#define NBUFFERS 2

using namespace std;

mxArray *bufArray = NULL;
bool init         = false;
bool streamOn     = false;
int width         = WIDTH;
int height        = HEIGHT;
string dev        = string(VIDEO_DEVICE);

void mexExit(void)
{
  printf("Exiting uvcCam\n");
  v4l2_stream_off();
  v4l2_close();

  if (bufArray) {
    // Don't free mmap memory:
/*
    printf("Null'ing the Buffer Array (%0x)...\n",bufArray);
    mxSetData(bufArray, NULL);
    printf("Destroying the Buffer Array...\n");
    mxDestroyArray(bufArray);
    printf("Done with the Buffer Array!\n");
*/
    //instead of destroying the array, re-assign it to a dummy matrix
    //this memory will be free'd when the matlab's variable is released from memory
    bufArray = mxCreateNumericMatrix(width/2, height, mxUINT32_CLASS, mxREAL);
  }
}

string GetString(const mxArray * mxStr)
{
  char * strChar = mxArrayToString(mxStr);
  if (strChar)
  {
    string ret = string(strChar);
    mxFree(strChar);
    return ret;
  }
  else
  {
    string ret = string("");
    return ret;
  }
}

void CheckConnection()
{
  if (!init)
    mexErrMsgTxt("not initialized");
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  string cmd = GetString(prhs[0]);

  if (cmd == "init")
  {
    if (!init)
    {
      if (nrhs>1) dev = GetString(prhs[1]);
      if (nrhs>2)
      {
        width  = mxGetPr(prhs[2])[0];
        height = mxGetPr(prhs[2])[1];

        if (width < 0 || height < 0 || width > 10000 || height > 10000)
          mexErrMsgTxt("bad width or height");
      }

      printf("opening video device %s ...",dev.c_str()); fflush(stdout);
      if (v4l2_open(dev.c_str()))
        mexErrMsgTxt("could not open device");

      bufArray = mxCreateNumericMatrix(width/2, height, mxUINT32_CLASS, mxREAL);
      mexMakeArrayPersistent(bufArray);
      mxFree(mxGetData(bufArray));
      
      if (v4l2_init())
        mexErrMsgTxt("could not initialize device");

      mexAtExit(mexExit);
      init = true;
      printf("done\n");
    }
  }
  
  else if (cmd == "read")
  {
    CheckConnection();
    int ibuf = v4l2_read_frame();
    if (ibuf >= 0) {
      mxSetData(bufArray, v4l2_get_buffer(ibuf, NULL));
      plhs[0] = bufArray;
      return;
    }
    else {
      plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
      return;
    }
  }
  else if (cmd == "get_ctrl")
  {
    CheckConnection();
    char *key = mxArrayToString(prhs[1]);
    int value;
    int ret = v4l2_get_ctrl(key, &value);
    plhs[0] = mxCreateDoubleScalar(value);
    if (key) mxFree(key);
    return;
  }
  else if (cmd == "set_ctrl")
  {
    CheckConnection();
    char *key = mxArrayToString(prhs[1]);
    int value = mxGetScalar(prhs[2]);
    int ret = v4l2_set_ctrl(key, value);
    plhs[0] = mxCreateDoubleScalar(ret);
    if (key) mxFree(key);
    return;
  }
  else if (cmd == "stream_on")
  {
    CheckConnection();
    if (!streamOn)
      v4l2_stream_on();
    streamOn = true;
  }
  else if (cmd == "stream_off")
  {
    CheckConnection();
    if (streamOn)
      v4l2_stream_off();
    streamOn = false;
  }
  else {
    mexErrMsgTxt("Unknown command");
  }

  plhs[0] = mxCreateDoubleScalar(0);
}
