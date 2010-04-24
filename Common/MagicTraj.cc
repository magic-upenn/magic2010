#include "MexIpcSerialization.hh"
#include "MagicTraj.hh"

using namespace Magic;


//TrajWaypoint
int TrajWaypoint::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;
  
  MEX_READ_FIELD(mxArr,index,x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,yaw,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,v,numFieldsRead);
  
  return numFieldsRead;
}

int TrajWaypoint::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "x","y","yaw","v"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int TrajWaypoint::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,x);
  MEX_WRITE_FIELD(mxArr,index,y);
  MEX_WRITE_FIELD(mxArr,index,yaw);
  MEX_WRITE_FIELD(mxArr,index,v);
  return 0;
}



//Traj
int Traj::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;
  
  MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,size,numFieldsRead);
  
  mxArray * mxWaypoints = mxGetField(mxArr,index,"waypoints");
  
  if (!mxWaypoints)
    mexErrMsgTxt("waypoints field must be present");

  int numWaypointsMat = mxGetNumberOfElements(mxWaypoints);
  if (numWaypointsMat != size)
    mexErrMsgTxt("size field must match the length of waypoints");
    
  waypoints = new TrajWaypoint[size];
  for (int ii=0; ii<size; ii++)
  {
    if (waypoints[ii].ReadFromMatlab(mxWaypoints,ii) < 1)
      mexErrMsgTxt("could not read a waypoint");
  }
    
  numFieldsRead++;
  
  return numFieldsRead;
}

int Traj::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "t","size","waypoints"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int Traj::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,t);
  MEX_WRITE_FIELD(mxArr,index,size);
  
  mxArray * mxWaypoints;
  TrajWaypoint::CreateMatlabStructMatrix(&mxWaypoints,size,1);
  mxSetField(mxArr,index,"waypoints",mxWaypoints);
  
  for (int ii=0; ii<size; ii++)
    waypoints[ii].WriteToMatlab(mxWaypoints,ii);
  
  return 0;
}
