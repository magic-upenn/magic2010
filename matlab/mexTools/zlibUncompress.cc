#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <vector>
#include "zlib.h"
#include <mex.h>
#define BYTE uint8_t

using namespace std;

vector<uint8_t> temp;

int UncompressData( const BYTE* abSrc, int nLenSrc, BYTE* abDst, int nLenDst )
{
    z_stream zInfo ={0};
    zInfo.total_in=  zInfo.avail_in=  nLenSrc;
    zInfo.total_out=0;
    zInfo.avail_out= nLenDst;
    zInfo.next_in= (BYTE*)abSrc;
    zInfo.next_out= abDst;

    int nErr, nRet= -1;
    nErr= inflateInit( &zInfo );
    if (nErr != Z_OK)
      mexErrMsgTxt("could not initialized inflate");

    
    nErr= inflate( &zInfo, Z_FINISH );
    if ( nErr == Z_STREAM_END ) {
        nRet= zInfo.total_out;
    }
    else
      mexErrMsgTxt("could not inflate");
    
    inflateEnd( &zInfo );
    return( nRet ); // -1 or len of output
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 1) mexErrMsgTxt("need exactly one argument");

  int lenSrc = mxGetNumberOfElements(prhs[0])*mxGetElementSize(prhs[0]);
  uint8_t * dataSrc = (uint8_t*)mxGetData(prhs[0]);
  
  temp.resize(lenSrc*100);

  //printf("%d %d\n",lenSrc,lenDst);
  int lenUnpacked= UncompressData( dataSrc, lenSrc, &(temp[0]), lenSrc*100 );

  if (lenUnpacked > 0)
  {
    const int ndims =2;
    int dims[] = {1,lenUnpacked};
    plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT8_CLASS,mxREAL);
    memcpy(mxGetData(plhs[0]),&(temp[0]),lenUnpacked);
  }
  else
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);

}
