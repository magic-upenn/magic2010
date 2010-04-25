/* 
  status = ipcMarshall(args);

  Matlab Unix MEX file for Marshalling data for IPC 3.8.3, which can be
  found here: http://www.cs.cmu.edu/afs/cs/project/TCA/www/ipc/index.html

  compile with:
  mex -O ipcMarshall.cc -lipc

  Alex Kushleyev
  University of Pennsylvania
  June, 2009
  akushley (at) seas (dot) upenn (dot) edu
*/

#include "mex.h"
#include "ipc.h"
#include <string>
#include "string.h"
#include <set>
#include <deque>
#include <unistd.h>
#include <iostream>
#include "VisInterfaces.hh"
//#include <sys/types.h>

using namespace std;

static bool initialized = false;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!initialized)
  {
    if (IPC_initialize() != IPC_OK)
      mexErrMsgTxt("ipcMarshall: Could not read string. (1st argument)");
    initialized=true;
  }

  const int BUFLEN = 256;
  char command[BUFLEN];	

  if (mxGetString(prhs[0], command, BUFLEN) != 0)
    mexErrMsgTxt("ipcMarshall: Could not read string. (1st argument)");


  //First argument is the struct type
  if (strcmp(command, "Pose3D") == 0)
  {
    if (mxGetNumberOfElements(prhs[1]) != 6)
      mexErrMsgTxt("ipcMarshall: not enough elements for the pose");

    IPC_VARCONTENT_TYPE varcontent;
    vis::Pose3D pose;

    double * dataIn = (double *)mxGetPr(prhs[1]);
    pose.pos.x     = *dataIn++;
    pose.pos.y     = *dataIn++;
    pose.pos.z     = *dataIn++;
    pose.rot.roll  = *dataIn++;
    pose.rot.pitch = *dataIn++;
    pose.rot.yaw   = *dataIn++;

    if (IPC_marshall( IPC_parseFormat(Pose3D_IPC_FORMAT), &pose, &varcontent) != IPC_OK)
      mexErrMsgTxt("ipcMarshall: error marshalling a message");

    int dims[2];
    dims[0] = 1;
    dims[1] = varcontent.length;
    plhs[0] = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
    memcpy(mxGetData(plhs[0]),varcontent.content,varcontent.length);
    IPC_freeByteArray(varcontent.content);

    return;
  }

  else
    mexErrMsgTxt("ipcMarshall: command not recognized");

  return;
}
