/* 
  status = ipcMarshall(args);

  Matlab Unix MEX file for Marshalling data for IPC 3.8.3, which can be
  found here: http://www.cs.cmu.edu/afs/cs/project/TCA/www/ipc/index.html

  compile with:
  mex -O ipcMarshall.cc -lipc

  Alex Kushleyev
  University of Pennsylvania
  June, 2009
  akushley (at) seas (dot) upenn (dot) edu
*/

#include "mex.h"
#include "ipc.h"
#include <string>
#include "string.h"
#include <set>
#include <deque>
#include <unistd.h>
#include <iostream>
#include "VisInterfaces.hh"
//#include <sys/types.h>

using namespace std;
using namespace vis;

static bool initialized = false;

void CreateOutputAndFreeVarcontent(mxArray ** output, IPC_VARCONTENT_TYPE * varcontent)
{
  int dims[2];
  dims[0] = 1;
  dims[1] = varcontent->length;
  output[0]  = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
  memcpy(mxGetData(output[0]),varcontent->content,varcontent->length);
  IPC_freeByteArray(varcontent->content);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!initialized)
  {
    if (IPC_initialize() != IPC_OK)
      mexErrMsgTxt("ipcMarshall: Could not read string. (1st argument)");
    initialized=true;
  }

  const int BUFLEN = 256;
  char command[BUFLEN];	

  if (mxGetString(prhs[0], command, BUFLEN) != 0)
    mexErrMsgTxt("ipcMarshall: Could not read string. (1st argument)");


  if (strcmp(command, "marshall") == 0)
  {
    if (mxGetString(prhs[1], command, BUFLEN) != 0)
      mexErrMsgTxt("ipcMarshall: Could not read string. (2nd argument)");

    if (nrhs != 3)
      mexErrMsgTxt("ipcMarshall: need 3 arguments");

    //Second argument is the struct type
    if (strcmp(command, "Pose3D") == 0)
    {
      if (mxGetNumberOfElements(prhs[2]) != 6)
        mexErrMsgTxt("ipcMarshall: not enough elements for the pose");

      IPC_VARCONTENT_TYPE varcontent;
      vis::Pose3D pose;

      double * dataIn = (double *)mxGetPr(prhs[2]);
      pose.pos.x     = *dataIn++;
      pose.pos.y     = *dataIn++;
      pose.pos.z     = *dataIn++;
      pose.rot.roll  = *dataIn++;
      pose.rot.pitch = *dataIn++;
      pose.rot.yaw   = *dataIn++;

      if (IPC_marshall( IPC_parseFormat(vis::Pose3D::getIPCFormat()), &pose, &varcontent) != IPC_OK)
        mexErrMsgTxt("ipcMarshall: error marshalling a message");

      CreateOutputAndFreeVarcontent(plhs,&varcontent);
      return;
    }

    //Second argument is the struct type
    else if (strcmp(command, "PointCloud3DColorDoubleRGBA") == 0)
    {
      int nPoints = (int)mxGetN(prhs[2]);
      int m = (int)mxGetM(prhs[2]);
      double * data = (double*)mxGetPr(prhs[2]);
         

      if (m != 7)
        mexErrMsgTxt("ipcMarshall: PointCloud3DColorDoubleRGBA requires 7 rows of data");

      IPC_VARCONTENT_TYPE varcontent;
      vis::PointCloud3DColorDoubleRGBA pointCloud;

      vis::Pos3DColorDoubleRGBA * points = new vis::Pos3DColorDoubleRGBA[nPoints];
      vis::Pos3DColorDoubleRGBA * p = points;

      //cout <<"length="<<nPoints<<endl;

      for (int ii=0; ii<nPoints; ii++)
      {
        p->pos.x = *data++;
        p->pos.y = *data++;
        p->pos.z = *data++;
        p->color.r = *data++;
        p->color.g = *data++;
        p->color.b = *data++;
        p->color.a = *data++;
        p++;
      }
    
      pointCloud.points = points;
      pointCloud.numPoints = nPoints;

      if (IPC_marshall( IPC_parseFormat(vis::PointCloud3DColorDoubleRGBA::getIPCFormat()), 
                                                        &pointCloud, &varcontent) != IPC_OK)
        mexErrMsgTxt("ipcMarshall: error marshalling a message");

      delete [] points;

      CreateOutputAndFreeVarcontent(plhs,&varcontent);
      return;
    }

    if (strcmp(command, "Rot3DMatrix") == 0)
    {
      if (mxGetNumberOfElements(prhs[2]) != 9)
        mexErrMsgTxt("ipcMarshall: not enough elements for the pose");

      IPC_VARCONTENT_TYPE varcontent;
      vis::Matrix3x3Double mx;

      double * dataIn = (double *)mxGetPr(prhs[2]);
      memcpy(&mx.data,dataIn,9*sizeof(double));      

      if (IPC_marshall( IPC_parseFormat(vis::Matrix3x3Double::getIPCFormat()), &mx, &varcontent) != IPC_OK)
        mexErrMsgTxt("ipcMarshall: error marshalling a message");

      CreateOutputAndFreeVarcontent(plhs,&varcontent);
      return;
    }

    else if (strcmp(command, "TrajPos3DColorDoubleRGBA") == 0)
    {
      if (mxGetM(prhs[2]) != 7)
        mexErrMsgTxt("ipcMarshall: not enough elements for the trajectory");

      IPC_VARCONTENT_TYPE varcontent;
      vis::TrajPos3DColorDoubleRGBA traj;
      
      traj.numPoints = mxGetN(prhs[2]);
      traj.points = new vis::Pos3DColorDoubleRGBA[traj.numPoints];
      vis::Pos3DColorDoubleRGBA * points = traj.points;

      double * data = (double*)mxGetPr(prhs[2]);

      //stuff the data
      for (int ii=0; ii<traj.numPoints; ii++)
      {
        points->pos.x   = *data++;
        points->pos.y   = *data++;
        points->pos.z   = *data++;
        points->color.r = *data++;
        points->color.g = *data++;
        points->color.b = *data++;
        points->color.a = *data++;
        points++;
      }

      if (IPC_marshall( IPC_parseFormat(vis::TrajPos3DColorDoubleRGBA::getIPCFormat()), 
                                                         &traj, &varcontent) != IPC_OK)
        mexErrMsgTxt("ipcMarshall: error marshalling a message");

      delete [] traj.points;

      CreateOutputAndFreeVarcontent(plhs,&varcontent);
      return;
    }


    else if (strcmp(command, "ImageData") == 0)
    {
      int height = mxGetM(prhs[2]);
      int width  = mxGetN(prhs[2])/3;

      IPC_VARCONTENT_TYPE varcontent;

      uint8_t * data = (uint8_t*)mxGetData(prhs[2]);
      vis::ImageData imageData;
      imageData.pixelFormat = VIS_PIXEL_FORMAT_MATLAB_RGB; 
      imageData.data        = (char*)data;
      imageData.height      = height;
      imageData.width       = width;
      imageData.pixelSize   = 3;
      imageData.pixelDim    = 0;
      imageData.timestamp   = 0;
      imageData.cntr        = 0;

      if (IPC_marshall( IPC_parseFormat(vis::ImageData::getIPCFormat()), 
                        &imageData, &varcontent) != IPC_OK)
        mexErrMsgTxt("ipcMarshall: error marshalling a message");

      CreateOutputAndFreeVarcontent(plhs,&varcontent);
      return;
    }

    else
      mexErrMsgTxt("ipcMarshall: struct type is not recognized");

  }


  if (strcmp(command, "unmarshall") == 0)
  {
    if (mxGetString(prhs[1], command, BUFLEN) != 0)
      mexErrMsgTxt("ipcUnarshall: Could not read string. (2nd argument)");

    if (nrhs != 3)
      mexErrMsgTxt("ipcUnarshall: need 3 arguments");

    //Second argument is the struct type
    if (strcmp(command, "Lidar2DDataDouble") == 0)
    {
      void * raw = mxGetData(prhs[2]);
      vis::Lidar2DDataDouble * lidarData;

      FORMATTER_PTR formatter = IPC_parseFormat(vis::Lidar2DDataDouble::getIPCFormat());

      if (IPC_unmarshall(formatter, raw, (void**)&lidarData) != IPC_OK)
        mexErrMsgTxt("could not deserialize data");

      int size = lidarData->ranges.size;

      //printf("size=%d\n",size);

      plhs[0] = mxCreateDoubleMatrix(size,1,mxREAL);
      double * pout = mxGetPr(plhs[0]);      
      double * pin = lidarData->ranges.data; 

      for (int ii=0; ii<size; ii++)
      {
        *pout++ = *pin++;
      }

      plhs[1] = mxCreateDoubleScalar(lidarData->timestamp);
  
      IPC_freeData(formatter, lidarData);

      return;
    }

    else if (strcmp(command, "Pose3D") == 0)
    {
      void * raw = mxGetData(prhs[2]);
      vis::Pose3D * pose;

      FORMATTER_PTR formatter = IPC_parseFormat(vis::Pose3D::getIPCFormat());

      if (IPC_unmarshall(formatter, raw, (void**)&pose) != IPC_OK)
        mexErrMsgTxt("could not deserialize data");

      plhs[0] = mxCreateDoubleScalar(pose->rot.yaw);
      //plhs[1] = mxCreateDoubleScalar(pose->t);

      IPC_freeData(formatter, pose);

      return;
    }

    else
      mexErrMsgTxt("ipcMarshall: struct type is not recognized");

  }


  else if (strcmp(command, "getMsgSuffix") == 0)
  {
    if (mxGetString(prhs[1], command, BUFLEN) != 0)
      mexErrMsgTxt("ipcMarshall: Could not read string. (2nd argument)");

    //Second argument is the struct type
    if (strcmp(command, "Pose3D") == 0)
    {
      plhs[0] = mxCreateString(POSE_3D_MSG_SUFFIX);
      return;
    }
    else if (strcmp(command, "PointCloud3DColorDoubleRGBA") == 0)
    {
      plhs[0] = mxCreateString(POINT_CLOUD_3D_COLOR_DOUBLE_RGBA_MSG_SUFFIX);
      return;
    }
    else if (strcmp(command, "Rot3DMatrix") == 0)
    {
      plhs[0] = mxCreateString(ROT_3D_MATRIX_MSG_SUFFIX);
      return;
    }
    else if (strcmp(command, "TrajPos3DColorDoubleRGBA") == 0)
    {
      plhs[0] = mxCreateString(TRAJ_POS_3D_COLOR_DOUBLE_RGBA_MSG_SUFFIX);
      return;
    }

    else if (strcmp(command, "ImageData") == 0)
    {
      plhs[0] = mxCreateString(IMAGE_DATA_MSG_SUFFIX);
      return;
    }

    else
      mexErrMsgTxt("ipcMarshall: struct type is not recognized");
  }


  else if (strcmp(command, "getMsgFormat") == 0)
  {
    if (mxGetString(prhs[1], command, BUFLEN) != 0)
      mexErrMsgTxt("ipcMarshall: Could not read string. (2nd argument)");

    //Second argument is the struct type
    if (strcmp(command, "Pose3D") == 0)
    {
      plhs[0] = mxCreateString(vis::Pose3D::getIPCFormat());
      return;
    }
    else if (strcmp(command, "PointCloud3DColorDoubleRGBA") == 0)
    {
      plhs[0] = mxCreateString(vis::PointCloud3DColorDoubleRGBA::getIPCFormat());
      return;
    }
    else if (strcmp(command, "Rot3DMatrix") == 0)
    {
      plhs[0] = mxCreateString(vis::Matrix3x3Double::getIPCFormat());
      return;
    }

    else if (strcmp(command, "TrajPos3DColorDoubleRGBA") == 0)
    {
      plhs[0] = mxCreateString(vis::TrajPos3DColorDoubleRGBA::getIPCFormat());
      return;
    }

    else if (strcmp(command, "ImageData") == 0)
    {
      plhs[0] = mxCreateString(vis::ImageData::getIPCFormat());
      return;
    }

    else
      mexErrMsgTxt("ipcMarshall: struct type is not recognized");
  }
  else
    mexErrMsgTxt("ipcMarshall: command not recognized");

  return;
}
