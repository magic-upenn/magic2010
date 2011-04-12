#include "mex.h"
#include <stdint.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	// Get input arguments
	if (nrhs == 0)
		mexErrMsgTxt("Need input argument");

  const int N = 320;
  const int M = 240;


  int dims[3];
  dims[0] = M;
  dims[1] = N;
  dims[2] = 3;
  plhs[0] = mxCreateNumericArray(3,dims,mxUINT8_CLASS,mxREAL);  

  uint8_t * out = (uint8_t*)mxGetData(plhs[0]);
  uint8_t * in  = (uint8_t*)mxGetData(prhs[0]);


  for (int ii=0; ii<M; ii++)
  {
    for (int jj=0; jj<N; jj++)
    {
      uint8_t* out2 = out + ii + jj*M;
      float in0   = in[0];
      float in3   = in[3]-128;
      float in1   = in[1]-128;
      out2[0]     = in0 + 1.370705f*in3;
      out2[M*N]   = in0 - 0.698001f*in3 - 0.337633f*in1;
      out2[2*M*N] = in0 + 1.732446f*in1;
      in += 4;
    }
    in +=4*N;
  }
}

