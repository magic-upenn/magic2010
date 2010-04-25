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



//GpsASCIIPacket
int GpsASCII::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,size,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY_UINT8(mxArr,index,data,numFieldsRead);
  
  return numFieldsRead;
}
int GpsASCII::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= {"t", "id", "size", "data"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GpsASCII::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,id);
  MEX_WRITE_FIELD(mxArr,index,size);
  MEX_WRITE_FIELD_RAW_ARRAY_UINT8(mxArr,index,data,size);
  return 0;
} 


//EncodersPacket
int EncoderCounts::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,cntr,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,fr,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,fl,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,rr,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,rl,numFieldsRead);    
  
  return numFieldsRead;
}
int EncoderCounts::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= {"t", "cntr", "fr", "fl","rr","rl"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int EncoderCounts::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,cntr);
  MEX_WRITE_FIELD(mxArr,index,fr);
  MEX_WRITE_FIELD(mxArr,index,fl);
  MEX_WRITE_FIELD(mxArr,index,rr);
  MEX_WRITE_FIELD(mxArr,index,rl);
  return 0;
}


//VelocityCmd
int VelocityCmd::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,v,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,w,numFieldsRead); 
  
  return numFieldsRead;
}
int VelocityCmd::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= {"t", "v", "w"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int VelocityCmd::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,v);
  MEX_WRITE_FIELD(mxArr,index,w);
  return 0;
} 


