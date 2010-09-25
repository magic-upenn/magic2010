/*
  x = darwinCam(args);

  Matlab 7.4 Linux MEX file
  to read from USB uvc camera.
  
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
*/

#include <string>
#include "v4l2.h"
#include "mex.h"
#include "assert.h"
#define NBUFFERS 2

mxArray *bufArray = NULL;
V4l2 v4l2; 
void mexExit(void)
{
  v4l2.v4l2_stream_off();
  v4l2.v4l2_close();

  if (bufArray) {
    // Don't free mmap memory:
    printf("Null'ing the Buffer Array (%0x)...\n",bufArray);
    mxSetData(bufArray, NULL);
    printf("Destroying the Buffer Array...\n");
    mxDestroyArray(bufArray);
    printf("Done with the Buffer Array!\n");
  }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  std::string cmd = mxArrayToString(prhs[0]);
  if (cmd == "read") {
    int ibuf = v4l2.v4l2_read_frame();
    if (ibuf >= 0) {
      mxSetData(bufArray, v4l2.v4l2_get_buffer(ibuf, NULL));
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
    int ret = v4l2.v4l2_get_ctrl(key, &value);
    plhs[0] = mxCreateDoubleScalar(value);
    return;
  }
  else if (cmd == "set_ctrl") {
    char *key = mxArrayToString(prhs[1]);
    int value = mxGetScalar(prhs[2]);
    int ret = v4l2.v4l2_set_ctrl(key, value);
    plhs[0] = mxCreateDoubleScalar(ret);
    return;
  }
  else if (cmd == "init") {
    //char *cam = mxArrayToString(prhs[1]);
    v4l2.v4l2_open("/dev/video1");
    mexPrintf("%d %d",v4l2.get_width(),v4l2.get_height()); 
    int width = mxGetScalar(prhs[1]);
    int height = mxGetScalar(prhs[2]);
    v4l2.v4l2_init(width,height);
    bufArray = mxCreateNumericMatrix(v4l2.get_width()/2, v4l2.get_height(), mxUINT32_CLASS, mxREAL);
    mexMakeArrayPersistent(bufArray);
    mxFree(mxGetData(bufArray));
  }
  else if (cmd == "stream_on") {
    v4l2.v4l2_stream_on();
  }
  else if (cmd == "stream_off") {
    v4l2.v4l2_stream_off();
  }
  else {
    mexErrMsgTxt("Unknown command");
  }

  plhs[0] = mxCreateDoubleScalar(0);
}
