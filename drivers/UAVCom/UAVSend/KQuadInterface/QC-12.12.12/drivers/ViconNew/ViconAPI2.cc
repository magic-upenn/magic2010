/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
/* MEX interface to a Vicon system.

   Aleksandr Kushleyev
   kushlik (at) gmail (dot) com
   November 2011
*/


#include "ViconDriver2.hh"
#include "mex.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

using namespace std;

static ViconDriver2 * vicon = NULL;

//this will be executed when the mex file is unloaded
void mexExit(void)
{
  printf("Exiting Vicon2API\n"); fflush(stdout);
  if (vicon != NULL) 
  {
    delete vicon;
    vicon = NULL;
  }
}


mxArray * CreateLatencyInfoOutput(ViconData & vdata)
{
  mxArray * out = mxCreateDoubleMatrix(4,1,mxREAL);
  double * pdata = mxGetPr(out);
  
  ViconLatencyInfo & info = vdata.latencyInfo;
  
  *pdata++ = info.delivered;
  *pdata++ = info.processed;
  *pdata++ = info.datastream;
  *pdata   = info.total;
  
  return out;
}

mxArray * CreatePoseOutput(ViconSubjectPose3D & pose)
{
  mxArray * out;

  const char *fields[] = {"xyz", "rpy","quat","rot","valid","visible"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  out = mxCreateStructMatrix(1, 1, nfields, fields);
  
  mxArray * xyzArray  = mxCreateDoubleMatrix(3,1,mxREAL);
  mxArray * rpyArray  = mxCreateDoubleMatrix(3,1,mxREAL);
  mxArray * quatArray = mxCreateDoubleMatrix(4,1,mxREAL);
  mxArray * rotArray  = mxCreateDoubleMatrix(9,1,mxREAL);
  mxArray * valArray  = mxCreateDoubleMatrix(4,1,mxREAL);
  mxArray * visArray  = mxCreateDoubleScalar(pose.visible);
  
  memcpy(mxGetPr(xyzArray),pose.xyz,3*sizeof(double));
  memcpy(mxGetPr(rpyArray),pose.rpy,3*sizeof(double));
  memcpy(mxGetPr(quatArray),pose.quat,4*sizeof(double));
  memcpy(mxGetPr(rotArray),pose.rot,9*sizeof(double));
  
  double * pvalid = mxGetPr(valArray);
  
  *pvalid++ = pose.validXyz;
  *pvalid++ = pose.validRpy;
  *pvalid++ = pose.validQuat;
  *pvalid++ = pose.validRot;
  
  mxSetField(out,0,"xyz",xyzArray);
  mxSetField(out,0,"rpy",rpyArray);
  mxSetField(out,0,"quat",quatArray);
  mxSetField(out,0,"rot",rotArray);
  mxSetField(out,0,"valid",valArray);
  mxSetField(out,0,"visible",visArray);

  
  return out;
}

mxArray * CreateLabeledMarkersOutput(std::list<ViconLabeledMarker> & markers)
{
  mxArray * out;
  int size = markers.size();
  
  if (size>0)
  {
    std::list<ViconLabeledMarker>::iterator it = markers.begin();
    
    const char *fields[] = {"name", "xyz","visible"};
    const int nfields = sizeof(fields)/sizeof(*fields);
    out = mxCreateStructMatrix(size, 1, nfields, fields);
    
    for (int ii=0; ii<size; ii++)
    {
      ViconLabeledMarker & marker = *it++;
      mxArray * nArray = mxCreateString(marker.name.c_str());
      mxArray * pArray = mxCreateDoubleMatrix(3,1,mxREAL);
      mxArray * vArray = mxCreateDoubleScalar(marker.visible);
      
      double * pdata = mxGetPr(pArray);
      *pdata++ = marker.xyz[0];
      *pdata++ = marker.xyz[1];
      *pdata++ = marker.xyz[2];
      
      mxSetField(out,ii,"name",nArray);
      mxSetField(out,ii,"xyz",pArray);
      mxSetField(out,ii,"visible",vArray);
    }
  }
  else
    out = mxCreateDoubleMatrix(0,0,mxREAL);
  
  return out;
}

mxArray * CreateSubjectsOutput(ViconData & vdata)
{
  mxArray * out;
  int size = vdata.subjects.size();
  
  if (size > 0)
  {
    const char *fields[] = {"name", "pose","markers"};
    const int nfields = sizeof(fields)/sizeof(*fields);
    out = mxCreateStructMatrix(size, 1, nfields, fields);
    
    std::list<ViconSubject>::iterator it = vdata.subjects.begin();
    
    for (int ii=0; ii<size; ii++)
    {
      ViconSubject & subject = *it++;
      
      mxArray * nArray = mxCreateString(subject.name.c_str());
      mxArray * pArray = CreatePoseOutput(subject.pose);
      mxArray * mArray = CreateLabeledMarkersOutput(subject.markers);
      
      mxSetField(out,ii,"name",nArray);
      mxSetField(out,ii,"pose",pArray);
      mxSetField(out,ii,"markers",mArray);
    }
    
    
  }
  else
    out = mxCreateDoubleMatrix(0,0,mxREAL);
  
  return out;
}

mxArray * CreateUnlabeledMarkersOutput(ViconData & vdata)
{
  int size = vdata.unlabeledMarkers.size();
  mxArray * out;
  
  if (size > 0)
  {
    out = mxCreateDoubleMatrix(3,size,mxREAL);
    double * pdata = mxGetPr(out);
    
    std::list<ViconUnlabeledMarker>::iterator it = vdata.unlabeledMarkers.begin();
    
    for (int ii=0; ii<size; ii++)
    {
      ViconUnlabeledMarker & marker = *it++;
      *pdata++ = marker.xyz[0];
      *pdata++ = marker.xyz[1];
      *pdata++ = marker.xyz[2];
    }
  }
  else
    out = mxCreateDoubleMatrix(0,0,mxREAL);
  
  return out;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Get input arguments
  if (nrhs == 0) mexErrMsgTxt("Vicon2API: Need input argument");
  
  const int BUFLEN = 256;
  char command[BUFLEN];

  if (mxGetString(prhs[0], command, BUFLEN) != 0) mexErrMsgTxt("Vicon2API: Could not read string.");

  //connect to vicon
  if (strcasecmp(command, "connect") == 0)
  {
    if (vicon != NULL) 
    {
      printf("Vicon2API: Port is already open\n");
      plhs[0] = mxCreateDoubleScalar(0);
      return;
    }

    if (nrhs < 2) mexErrMsgTxt("Vicon2API: Please enter correct arguments: 'connect', 'hostname:port'");

    char hostname[BUFLEN];
    if (mxGetString(prhs[1], hostname, BUFLEN) != 0) 
      mexErrMsgTxt("Vicon2API: Could not read string while reading the ip/hostname name");
    
    vicon = new ViconDriver2();

    //connect to the device and set IO mode (see SerialDevice.hh for modes)
    if (vicon->Connect(hostname))
    {
      delete vicon;
      vicon=NULL;
      mexErrMsgTxt("Vicon2API: Could not connect to device");
    }
    
    //set the atExit function
    mexAtExit(mexExit);

    printf("Vicon2API: Connected to device: %s\n",hostname);
    plhs[0] = mxCreateDoubleScalar(0);
    return;
  }
  
  //disconnect from vicon
  else if (strcasecmp(command, "disconnect") == 0)
  {
    delete vicon;
    vicon = NULL;
    plhs[0] = mxCreateDoubleScalar(0);
    return;
  }
  
  //get names of all the fields in vicon packet
  else if (strcasecmp(command, "get_data") == 0)
  {
    if (vicon == NULL) mexErrMsgTxt("viconAPI: Not connected to device");
    if (!vicon->IsConnected()) mexErrMsgTxt("viconAPI: Not connected to device");
    
    
    std::list<ViconData> data;
    int size = vicon->GetViconData(data);
    
    if (size < 1)
    {
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    
    const char *fields[] = {"frameCntr", "unixTime","latencyInfo","subjects","unlabeledMarkers"};
    const int nfields = sizeof(fields)/sizeof(*fields);
    plhs[0] = mxCreateStructMatrix(size, 1, nfields, fields);
    
    std::list<ViconData>::iterator it = data.begin();
    
    for (int ii=0; ii<size; ii++)
    {
      ViconData & vdata = *it++;
      
      mxArray * fArray = mxCreateDoubleScalar(vdata.frameCntr);
      mxArray * uArray = mxCreateDoubleScalar(vdata.unixTime);
      mxArray * lArray = CreateLatencyInfoOutput(vdata);
      mxArray * sArray = CreateSubjectsOutput(vdata);
      mxArray * mArray = CreateUnlabeledMarkersOutput(vdata);
      
      mxSetField(plhs[0],ii,"frameCntr",fArray);
      mxSetField(plhs[0],ii,"unixTime",uArray);
      mxSetField(plhs[0],ii,"latencyInfo",lArray);
      mxSetField(plhs[0],ii,"subjects",sArray);
      mxSetField(plhs[0],ii,"unlabeledMarkers",mArray);
    }
    
  }
  else mexErrMsgTxt("Vicon2API: unknown command");
}

