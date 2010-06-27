#include "mex.h"
#include <sys/resource.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const char *fields[] = {"UserTime","SystemTime"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(1, 1, nfields, fields);

  struct rusage ru;
  getrusage(RUSAGE_SELF,&ru);

  double utime = ru.ru_utime.tv_sec + ru.ru_utime.tv_usec*0.000001;
  double stime = ru.ru_stime.tv_sec + ru.ru_stime.tv_usec*0.000001;

  mxSetField(plhs[0], 0, "UserTime", mxCreateDoubleScalar(utime));
  mxSetField(plhs[0], 0, "SystemTime", mxCreateDoubleScalar(stime));
}

