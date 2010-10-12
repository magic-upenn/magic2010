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

bool init_status(bool set_init = 0)
{
	static bool init = 0;
	if (set_init) init = 1; 
	return init;  
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
  mexAtExit(&mexExit);
  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }
  
  std::string cmd = mxArrayToString(prhs[0]);

  if (cmd == "is_init") {
    plhs[0] = mxCreateDoubleScalar(init_status());
    return;
  }	
 	 
  if (cmd == "init" && ~init_status()) {
    char *cam = mxArrayToString(prhs[1]);
    v4l2.v4l2_open(cam);
    mexPrintf("%d %d",v4l2.get_width(),v4l2.get_height()); 
    int width = mxGetScalar(prhs[2]);
    int height = mxGetScalar(prhs[3]);
    v4l2.v4l2_init(width,height);
    bufArray = mxCreateNumericMatrix(v4l2.get_width()/2, v4l2.get_height(), mxUINT32_CLASS, mxREAL);
    mexMakeArrayPersistent(bufArray);
    mxFree(mxGetData(bufArray));
    init_status(1);  
    plhs[0] = mxCreateDoubleScalar(1);
    return; 
  }
	
  if (init_status() == 0)
  { 
    mexPrintf("***Camera not initialized***"); 
    plhs[0] = mxCreateDoubleScalar(0);
    return; 
  }

  if (cmd == "stream_on") {
    v4l2.v4l2_stream_on();
    plhs[0] = mxCreateDoubleScalar(1);
    return; 
  }
  else if (cmd == "read") {
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
  else if (cmd == "stream_off") {
    v4l2.v4l2_stream_off();
    plhs[0] = mxCreateDoubleScalar(1);
  }
  else {
    mexErrMsgTxt("Unknown command");
  }

  plhs[0] = mxCreateDoubleScalar(0);
}
