#include "MexIpcSerialization.hh"
#include "MagicSensorDataTypes.hh"

using namespace Magic;

//Lidar Scan
int LidarScan::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,counter,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,startAngle,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,stopAngle,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,angleStep,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,startTime,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,stopTime,numFieldsRead);
  
  MEX_READ_FIELD_ARRAY_FLOAT(mxArr,index,ranges,numFieldsRead);
  MEX_READ_FIELD_ARRAY_UINT16(mxArr,index,intensities,numFieldsRead);

  return numFieldsRead;
}

int LidarScan::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "counter","id","ranges","intensities","startAngle",
                           "stopAngle","angleStep","startTime","stopTime"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int LidarScan::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,counter);
  MEX_WRITE_FIELD(mxArr,index,id);
  MEX_WRITE_FIELD_ARRAY_FLOAT(mxArr,index,ranges);
  MEX_WRITE_FIELD_ARRAY_UINT16(mxArr,index,intensities);
  MEX_WRITE_FIELD(mxArr,index,startAngle);
  MEX_WRITE_FIELD(mxArr,index,stopAngle);
  MEX_WRITE_FIELD(mxArr,index,angleStep);
  MEX_WRITE_FIELD(mxArr,index,startTime);
  MEX_WRITE_FIELD(mxArr,index,stopTime);

  return 0;
}

//ServoState
int ServoState::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,counter,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,position,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,velocity,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,acceleration,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  
  return numFieldsRead;
}

int ServoState::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "counter","id","position","velocity","acceleration","t"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int ServoState::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,counter);
  MEX_WRITE_FIELD(mxArr,index,id);
  MEX_WRITE_FIELD(mxArr,index,position);
  MEX_WRITE_FIELD(mxArr,index,velocity);
  MEX_WRITE_FIELD(mxArr,index,acceleration);
  MEX_WRITE_FIELD(mxArr,index,t);
  return 0;
}

//ImuFiltered
int ImuFiltered::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,roll,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,pitch,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,yaw,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,wroll,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,wpitch,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,wyaw,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  
  return numFieldsRead;
}

int ImuFiltered::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "roll","pitch","yaw","wroll","wpitch","wyaw","t"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int ImuFiltered::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,roll);
  MEX_WRITE_FIELD(mxArr,index,pitch);
  MEX_WRITE_FIELD(mxArr,index,yaw);
  MEX_WRITE_FIELD(mxArr,index,wroll);
  MEX_WRITE_FIELD(mxArr,index,wpitch);
  MEX_WRITE_FIELD(mxArr,index,wyaw);
  MEX_WRITE_FIELD(mxArr,index,t);
  return 0;
}
    
    