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

mxArray *bufArray = NULL;
bool initMexfile = false;
bool initV4l2    = false;
bool streamOn    = false;

void mexExit(void)
{
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
    bufArray = mxCreateNumericMatrix(WIDTH/2, HEIGHT, mxUINT32_CLASS, mxREAL);
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!initMexfile) {
    printf("opening video device..."); fflush(stdout);
    v4l2_open(VIDEO_DEVICE);

    bufArray = mxCreateNumericMatrix(WIDTH/2, HEIGHT, mxUINT32_CLASS, mxREAL);
    mexMakeArrayPersistent(bufArray);
    mxFree(mxGetData(bufArray));
    initMexfile = true;
    mexAtExit(mexExit);
    printf("done\n");
  }
  
  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  std::string cmd = mxArrayToString(prhs[0]);
  if (cmd == "read") {
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
  else if (cmd == "get_ctrl") {
    char *key = mxArrayToString(prhs[1]);
    int value;
    int ret = v4l2_get_ctrl(key, &value);
    plhs[0] = mxCreateDoubleScalar(value);
    return;
  }
  else if (cmd == "set_ctrl") {
    char *key = mxArrayToString(prhs[1]);
    int value = mxGetScalar(prhs[2]);
    int ret = v4l2_set_ctrl(key, value);
    plhs[0] = mxCreateDoubleScalar(ret);
    return;
  }
  else if (cmd == "init") {
    if (!initV4l2)
    {
      v4l2_init();
      initV4l2 = true;
    }
  }
  else if (cmd == "stream_on") {
    if (!streamOn)
      v4l2_stream_on();
    streamOn = true;
  }
  else if (cmd == "stream_off") {
    if (streamOn)
      v4l2_stream_off();
    streamOn = false;
  }
  else {
    mexErrMsgTxt("Unknown command");
  }

  plhs[0] = mxCreateDoubleScalar(0);
}
