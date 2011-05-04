/*
  x = time;

  MEX file to calculate Unix time.

  Daniel D. Lee, 4/09 <ddlee@seas.upenn.edu>
*/

#include <sys/time.h>
#include "mex.h"

static struct timeval t;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  gettimeofday(&t, NULL);
  plhs[0] = mxCreateDoubleScalar(t.tv_sec + 1E-6*t.tv_usec);
}
