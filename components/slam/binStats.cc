/*
  s = binStats(x, y, n);
  Returns struct containing statistics of vector y
  binned according to round(x), up to optional size n

  mex -O binStats.cc
*/

#include <math.h>
#include <float.h>
#include <vector>
#include "mex.h"

std::vector<int> count;
std::vector<double> sumY, sumYY, maxY, minY;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 2) {
    mexErrMsgTxt("Need at least two input arguments");
  }

  int nX = mxGetNumberOfElements(prhs[0]);
  if (mxGetNumberOfElements(prhs[1]) != nX)
    mexErrMsgTxt("Number of elements in inputs should match");

  double *prX = mxGetPr(prhs[0]);
  double *prY = mxGetPr(prhs[1]);

  int n = 0;
  if (nrhs >= 3) {
    n = mxGetScalar(prhs[2]);
  }
  else {
    // Find max value of x:
    for (int i = 0; i < nX; i++) {
      if (prX[i] > n) n = round(prX[i]);
    }
  }

  // Initialize statistics vectors:
  count.resize(n);
  sumY.resize(n);
  sumYY.resize(n);
  maxY.resize(n);
  minY.resize(n);
  for (int i = 0; i < n; i++) {
    count[i] = 0;
    sumY[i] = 0;
    sumYY[i] = 0;
    maxY[i] = -__FLT_MAX__;
    minY[i] = __FLT_MAX__;
  }

  for (int i = 0; i < nX; i++) {
    int j = round(prX[i]) - 1;
    if ((j >= 0) && (j < n)) {
      count[j]++;
      sumY[j] += prY[i];
      sumYY[j] += prY[i]*prY[i];
      if (prY[i] > maxY[j]) maxY[j] = prY[i];
      if (prY[i] < minY[j]) minY[j] = prY[i];
    }
  }

  const char *fields[] = {"count", "mean", "std", "max", "min"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(n, 1, nfields, fields);
  for (int i = 0; i < n; i++) { 
    mxSetField(plhs[0], i, "count", mxCreateDoubleScalar(count[i]));
    if (count[i] > 0) {
      mxSetField(plhs[0], i, "mean",
		 mxCreateDoubleScalar(sumY[i]/count[i]));
      mxSetField(plhs[0], i, "std",
		 mxCreateDoubleScalar(sqrt((sumYY[i]-sumY[i]*sumY[i]/count[i])/count[i]))); 
      mxSetField(plhs[0], i, "max", mxCreateDoubleScalar(maxY[i]));
      mxSetField(plhs[0], i, "min", mxCreateDoubleScalar(minY[i]));
    }
    else {
      mxSetField(plhs[0], i, "mean", mxCreateDoubleScalar(0));
      mxSetField(plhs[0], i, "std", mxCreateDoubleScalar(0));
      mxSetField(plhs[0], i, "max", mxCreateDoubleScalar(0));
      mxSetField(plhs[0], i, "min", mxCreateDoubleScalar(0));
    }
  }
}
