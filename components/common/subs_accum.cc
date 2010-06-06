/*
  y = subs_accum(x,i,j,v);

  MEX file to compute x(sub2ind(i,j)) = x(sub2ind(i,j)) + v;

  Note: This routine accumulates repeated indices and changes
  the matrix x directly in memory.

  Daniel D. Lee, 06/2007
  <ddlee@seas.upenn.edu>
*/

#include "mex.h"
#include <math.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 4)
    mexErrMsgTxt("Need four input arguments.");

  double *x = mxGetPr(prhs[0]);
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  double *indexI = mxGetPr(prhs[1]);
  int mi = mxGetM(prhs[1]);
  int ni = mxGetN(prhs[1]);

  double *indexJ = mxGetPr(prhs[2]);
  if ((mxGetM(prhs[2]) != mi) || (mxGetN(prhs[2]) != ni)) {
    mexErrMsgTxt("Index arrays need to be the same size");
  }

  double *value = mxGetPr(prhs[3]);
  int nvalue = mxGetNumberOfElements(prhs[3]);

  for (int k = 0; k < mi*ni; k++) {
    int i = (int) round(indexI[k]) - 1; // zero-indexing;
    int j = (int) round(indexJ[k]) - 1; // zero-indexing;

    if ((i >= 0) && (i < mx) && (j >= 0) && (j < nx)) {
      int index = mx*j + i;
      double v = (nvalue == 1) ? value[0] : value[k];
      x[index] += v;
    }
  }
  
  //  plhs[0] = (mxArray *)prhs[0];
  plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
}
