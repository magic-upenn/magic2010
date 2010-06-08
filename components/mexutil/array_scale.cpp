/*
  array_scale(x, s);

  MEX file to quickly calculate x = x*s

  Daniel D. Lee, 06/2007
  <ddlee@seas.upenn.edu>
*/

#include <math.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 2) {
    mexErrMsgTxt("Need three input arguments.");
  }

  double *x = mxGetPr(prhs[0]);
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  double s = mxGetScalar(prhs[1]);

  for (int i = 0; i < mx*nx; i++) {
    if (x[i] != 0) {
      x[i] *= s;
    }
  }

  plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
}
