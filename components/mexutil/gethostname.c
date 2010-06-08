/*
  s = gethostname;

  MEX file to get hostname.
*/

#include "unistd.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  size_t namelen = 255;
  char name[namelen];

  if (gethostname(name, namelen) != 0)
    mexErrMsgTxt("Could not get hostname");

  plhs[0] = mxCreateString(name);
}
