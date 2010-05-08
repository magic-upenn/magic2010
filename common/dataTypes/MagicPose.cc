#include "MexIpcSerialization.hh"
#include "MagicPose.hh"

using namespace Magic;


//Pose
int Pose::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;
  
  MEX_READ_FIELD(mxArr,index,x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,z,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,v,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,w,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,roll,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,pitch,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,yaw,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  
  return numFieldsRead;
}

int Pose::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "x","y","z","v","w","roll","pitch","yaw","t"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int Pose::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,x);
  MEX_WRITE_FIELD(mxArr,index,y);
  MEX_WRITE_FIELD(mxArr,index,z);
  MEX_WRITE_FIELD(mxArr,index,v);
  MEX_WRITE_FIELD(mxArr,index,w);
  MEX_WRITE_FIELD(mxArr,index,roll);
  MEX_WRITE_FIELD(mxArr,index,pitch);
  MEX_WRITE_FIELD(mxArr,index,yaw);
  MEX_WRITE_FIELD(mxArr,index,t);
  return 0;
}
