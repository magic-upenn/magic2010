/*  Matlab MEX file to interface to Dynamixel servo

    Aleksandr Kushleyev <akushley(at)seas(dot)upenn(dot)edu>
    University of Pennsylvania, 2009

*/

#include <string>
#include "Dynamixel.hh"
#include "mex.h"
#include <vector>


static Dynamixel *dynamixel = NULL;

void mexExit(void){
	printf("Exiting DynamixelAPI.\n");
	fflush(stdout);
	if (dynamixel!=NULL) 
  {
    dynamixel->StopDevice();
    dynamixel->Disconnect();
		delete dynamixel;
	}
}

void CreateEmptyOutput(mxArray * plhs[], int n)
{
  for (int ii=0; ii<n; ii++)
  {
    plhs[ii] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
}

void CheckConnection()
{
  if (dynamixel == NULL)
    mexErrMsgTxt("Device is not open");
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
	int ret;
  vector< float > values;
  vector<double> timeStamps;
  int n_points;
	int dims[2], port;
  int baud;
	
	// Get input arguments
	if (nrhs == 0) {
		mexErrMsgTxt("Need input argument");
	}
	
	const int BUFLEN = 256;
	char buf[BUFLEN];
	if (mxGetString(prhs[0], buf, BUFLEN) != 0) {
		mexErrMsgTxt("Could not read string.");
	}
	
	if (strcasecmp(buf, "connect") == 0) {
		if (dynamixel != NULL) {
			std::cout << "Port is already open \n" << std::endl;
			plhs[0] = mxCreateDoubleScalar(1);
			return;
		}
			
		if (nrhs != 4) mexErrMsgTxt("Please enter correct arguments: open <device> <baud rate> <moduleId>\n");


    if (mxGetString(prhs[1], buf, BUFLEN) != 0)
    {
			mexErrMsgTxt("Could not read string while reading the device name");
		}
		
		switch ((int)mxGetPr(prhs[2])[0]){
      case 9600:
				baud = 9600;
				break;
			case 19200:
				baud = 19200;
				break;
      case 38400:
				baud = 38400;
				break;
      case 57600:
				baud = 57600;
				break;
			case 115200:
				baud = 115200;
				break;
      case 1000000:
        baud = 1000000;
        break;
      case 2000000:
        baud = 2000000;
        break;
			default:
				mexErrMsgTxt("Invalid dynamixel baud rate. Options are 9600, 19200, 38400, 57600, 115200");
		}

    int id = mxGetPr(prhs[3])[0];

    // create an instance of the driver and initialize
	  dynamixel = new Dynamixel();

		if (dynamixel->Connect(buf,baud,id) || dynamixel->StartDevice())
    {
			delete dynamixel;
			dynamixel = NULL;
			mexErrMsgTxt("Unable to initialize Dynamixel!!!");
		}
		mexAtExit(mexExit);
		
		plhs[0] = mxCreateDoubleScalar(1);
		return;
	}
	
	else if (strcasecmp(buf, "getPosition") == 0)
  {
		CheckConnection();

    float position;
    if (dynamixel->GetPosition(position) != 0)
    {
      CreateEmptyOutput(plhs,1);
      return;
    }

    plhs[0] = mxCreateDoubleScalar(position);
    return;
	}

  else if (strcasecmp(buf, "setPosition") == 0)
  {
    CheckConnection();

    if (nrhs < 3)
      mexErrMsgTxt("provide target position and speed");

    float desPos   = mxGetPr(prhs[1])[0];
    float desSpeed = mxGetPr(prhs[2])[0];

    if (dynamixel->MoveToPos(desPos,desSpeed))
      mexErrMsgTxt("could not set position");

    plhs[0] = mxCreateDoubleScalar(1);
    return;
  }
  
  else {
		mexErrMsgTxt("wrong arguments.");
  }
}

