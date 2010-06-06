/*
  array_threshold(x, xmin, xmax);

  MEX file to threshhold array values xmin <= x <= xmax

  Daniel D. Lee, 06/2007
  <ddlee@seas.upenn.edu>
*/

#include <math.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 3) {
    mexErrMsgTxt("Need three input arguments.");
  }

  double *x = mxGetPr(prhs[0]);
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  double xmin = mxGetScalar(prhs[1]);
  double xmax = mxGetScalar(prhs[2]);

  for (int i = 0; i < mx*nx; i++) {
    if (x[i] < xmin) x[i] = xmin;
    else if (x[i] > xmax) x[i] = xmax;
  }

  plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
}
