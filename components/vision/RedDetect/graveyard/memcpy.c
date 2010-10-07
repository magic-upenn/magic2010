/*
  y = memcpy(x, classname);

  MEX file to convert raw data using memcpy.

  Daniel D. Lee, 1/07
  <ddlee@seas.upenn.edu>
*/

#include <string.h>

#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  unsigned char *x, *y;
  int dims[2];
  int m, n, elementSize;

  /* Check arguments */
  if (nrhs < 1)
    mexErrMsgTxt("Need one input arguments.");

  x = (unsigned char *) mxGetData(prhs[0]);
  m = mxGetM(prhs[0]);
  n = mxGetN(prhs[0]);
  elementSize = mxGetElementSize(prhs[0]);

  dims[0] = m;
  dims[1] = n*elementSize;
    
  plhs[0] = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
    
  y = (unsigned char *) mxGetData(plhs[0]);
  memcpy(y, x, m*n*elementSize);

}
