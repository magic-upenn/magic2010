#include "MexIpcSerialization.hh"
#include "MagicStatus.hh"

using namespace Magic;

int HeartBeat::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;
  MEX_READ_FIELD(mxArr,index,status,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_STRING(mxArr,index,sender,numFieldsRead);
  MEX_READ_STRING(mxArr,index,msgName,numFieldsRead);
  
  return numFieldsRead;
}

int HeartBeat::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "sender","msgName","status","t"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int HeartBeat::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,status);
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_STRING(mxArr,index,sender);
  MEX_WRITE_STRING(mxArr,index,msgName);
  return 0;
}
  
  