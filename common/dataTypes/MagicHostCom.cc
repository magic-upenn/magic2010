#include "MagicHostCom.hh"

using namespace Magic;

//IpcRawDynamixelPacket
int IpcRawDynamixelPacket::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,size,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY_UINT8(mxArr,index,data,numFieldsRead);
  
  return numFieldsRead;
}
int IpcRawDynamixelPacket::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= {"t","size","data"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int IpcRawDynamixelPacket::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,size);
  MEX_WRITE_FIELD_RAW_ARRAY_UINT8(mxArr,index,data,size);
  return 0;
}

