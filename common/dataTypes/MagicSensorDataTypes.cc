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


//ServoControllerCmd
int ServoControllerCmd::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,mode,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,minAngle,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,maxAngle,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,speed,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,acceleration,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  
  return numFieldsRead;
}

int ServoControllerCmd::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "id","mode","minAngle","maxAngle", "speed","acceleration","t"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int ServoControllerCmd::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,id);
  MEX_WRITE_FIELD(mxArr,index,mode);
  MEX_WRITE_FIELD(mxArr,index,minAngle);
  MEX_WRITE_FIELD(mxArr,index,maxAngle);
  MEX_WRITE_FIELD(mxArr,index,speed);
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


//EncodersCounts
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
  MEX_READ_FIELD(mxArr,index,vCmd,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,wCmd,numFieldsRead); 
  
  return numFieldsRead;
}
int VelocityCmd::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= {"t", "v", "w","vCmd","wCmd"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int VelocityCmd::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,v);
  MEX_WRITE_FIELD(mxArr,index,w);
  MEX_WRITE_FIELD(mxArr,index,vCmd);
  MEX_WRITE_FIELD(mxArr,index,wCmd);
  return 0;
} 

