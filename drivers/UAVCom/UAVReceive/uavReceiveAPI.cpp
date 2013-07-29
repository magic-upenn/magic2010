#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "udp.h"
#include "jpeg_decompress.h"
#include "mex.h"

#define BUFLEN 256

static bool connected=false;
static bool start=false;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  char command[BUFLEN];

  if(mxGetString(prhs[0],command,BUFLEN) != 0)
    mexErrMsgTxt(": Could not read first argument.");

  if (strcasecmp(command,"connect")==0) {
    if (connected) {
      printf("ipcAPI:
