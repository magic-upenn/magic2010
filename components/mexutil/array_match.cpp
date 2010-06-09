/*
  overlap = array_match(c, xp, yp, dx, dy, da);
  
  Returns accumulated overlap of points (xp(:), yp(:)),
  at 2D shift/rotations of dx, dy, da.
  where matrix c has coordinates 1..m, 1..n.

  mex -O array_match.cpp
*/

#include <math.h>
#include <float.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 6) {
    mexErrMsgTxt("Need at six input arguments");
  }

  int mc = mxGetM(prhs[0]);
  int nc = mxGetN(prhs[0]);
  double *c = mxGetPr(prhs[0]);

  int np = mxGetNumberOfElements(prhs[1]);
  if (np != mxGetNumberOfElements(prhs[2])) {
    mexErrMsgTxt("xp, yp don't match");
  }
  double *xp = mxGetPr(prhs[1]);
  double *yp = mxGetPr(prhs[2]);

  int ns = mxGetNumberOfElements(prhs[3]);
  if ((ns != mxGetNumberOfElements(prhs[4])) ||
      (ns != mxGetNumberOfElements(prhs[5]))) {
    mexErrMsgTxt("dx, dy, da don't match");
  }
  double *dx = mxGetPr(prhs[3]);
  double *dy = mxGetPr(prhs[4]);
  double *da = mxGetPr(prhs[5]);

  plhs[0] = mxCreateNumericArray(
    mxGetNumberOfDimensions(prhs[3]), mxGetDimensions(prhs[3]),
    mxDOUBLE_CLASS, mxREAL);
  double *olap = mxGetPr(plhs[0]);

  for (int is = 0; is < ns; is++) {
    olap[is] = 0;
    double ca = cos(da[is]);
    double sa = sin(da[is]);
    for (int ip = 0; ip < np; ip++) {
      // Use 0-indexing into matrix:
      int xs = round(ca*xp[ip] - sa*yp[ip] + dx[is]);
      int ys = round(sa*xp[ip] + ca*yp[ip] + dy[is]);
      if ((xs >= 0) && (xs < mc) && (ys >= 0) && (ys < nc)) {
	olap[is] += c[xs + mc*ys];
      }
    }
  }
}
