#include "HokuyoCircularHardware.hh"
#include "MagicSensorDataTypes.hh"
#include "MagicStatus.hh"
#include "Timer.hh"
#include <string>
#include <vector>
#include "ErrorMessage.hh"
#include <ipc.h>
#include <stdlib.h>

using namespace std;
using namespace Upenn;
using namespace Magic;


#define HOKUYO_DEF_DEVICE "/dev/ttyACM0"
#define HOKUYO_DEF_LOG_NAME "hokuyo"
//#define HOKUYO_DEF_DEVICE "/dev/cu.usbmodem3d11"

//SCAN_NAME is used to determine the scanType and scanSkip values
//See below for details

#define SCAN_NAME "range"
//#define SCAN_NAME "top_urg_range+intensity"
//#define SCAN_NAME "range+intensity1+AGC1"

HokuyoCircularHardware * dev = NULL;

void ShutdownFn(int code)
{
  PRINT_INFO("exiting..\n");
  if (dev)
  { 
    PRINT_INFO("Stopping thread\n");
	  if (dev->StopThread())
    {
		  PRINT_ERROR("could not stop thread\n");
	  }

	  PRINT_INFO("Stopping device\n");
	  if (dev->StopDevice())
    {
		  PRINT_ERROR("could not stop device\n");
	  }

    dev->Disconnect();
    delete dev;
  }
  exit(0);
}

int main(int argc, char * argv[])
{
  string address = string(HOKUYO_DEF_DEVICE);
  string ipcHost = string("localhost");

  string id = string("0");

  if (argc>=2)
    address = string(argv[1]);

  if (argc>=3)
    id = string(argv[2]);
  
  string logName          = string(HOKUYO_DEF_LOG_NAME) + id;
  string processName      = string("runHokuyo") + id;
  string robotName        = string("Robot0");
  string lidarScanMsgName = robotName + "/Lidar" + id;
  string hbeatMsgName     = robotName + "/HeartBeat";

  int nPoints = 1081;
  if (argc >=4)
    nPoints = strtol(argv[3],NULL,10);
  

  //connect to ipc  
  IPC_connectModule(processName.c_str(),ipcHost.c_str());

  IPC_defineMsg(lidarScanMsgName.c_str(),IPC_VARIABLE_LENGTH,
                 Magic::LidarScan::getIPCFormat());

  IPC_defineMsg(hbeatMsgName.c_str(),IPC_VARIABLE_LENGTH,
                 Magic::HeartBeat::getIPCFormat());

  int scanStart=0;      //start of the scan
  int scanEnd=nPoints -1;//1080;      //end of the scan
  int scanSkip=1;       //this is so-called "cluster count", however special values
                        //of this variable also let request Intensity and AGC values
                        //from URG-04LX. (see the intensity mode manual and Hokuyo.hh)

                        //If the scanner is 04LX and the scan name is not
                        //"range", then this skip value will be overwritten with the appropriate
                        //value in order to request the special scan. 
                        //See call to getScanTypeAndSkipFromName() below
                        
                        //Thus, for 04LX the skip (cluster)
                        //value is only effective if the scan name is "range". For 30LX, both
                        //"range" and "top_urg_range+intensity" should allow setting skip value
  

  int encoding=HOKUYO_3DIGITS; //HOKUYO_2DIGITS
                               //2 or 3 char encoding. 04LX supports both, but 30LX only 3-char
                               //2-char encoding reduces range to 4meters, but improves data
                               //transfer rates over standard serial port

  int scanType;                //scan type specifies whether a special scan is required, 
                               //such as HOKUYO_SCAN_SPECIAL_ME - for URG-30LX intensity mode
                               //otherwise use HOKUYO_SCAN_REGULAR. This will be automatically
                               //acquired by the getScanTypeAndSkipFromName() function below

  int baudRate=115200;            //communication baud rate (does not matter for USB connection)

  char scanName[128];        //name of the scan - see#include <iomanip> Hokuyo.hh for allowed types
  strcpy(scanName,SCAN_NAME); 



  const int numBuffers=50;      //number of buffers to be used in the circular buffer
  const int bufferSize = HOKUYO_MAX_DATA_LENGTH;
	dev = new HokuyoCircularHardware(bufferSize,numBuffers); //create an instance of HokuyoCircular

	PRINT_INFO("Connecting to device "<< address <<"\n");
  if (dev->Connect(address,baudRate))   //args: device name, baud rate
  {
		PRINT_ERROR("could not connect\n");
		return -1;
	}

/*
  if (dev->InitializeLogging(logName))   //initialize logging
  {
		PRINT_INFO("could not initialize logging\n");
		return -1;
	}

  if (dev->EnableLogging())   //enable logging
  {
		PRINT_INFO("could not enable logging\n");
		return -1;
	}
*/

  int sensorType= dev->GetSensorType();
  int newSkip;

  //get the special skip value (if needed) and scan type, depending on the scanName and sensor type
  if (dev->GetScanTypeAndSkipFromName(sensorType, scanName, &newSkip, &scanType)){
    PRINT_ERROR("Error getting the scan parameters\n");
    exit(1);
  }

  if (newSkip!=1){            //this means that a special value for skip must be used in order to request
    scanSkip=newSkip;         //a special scan from 04LX. Otherwise, just keep the above specified value of 
  }                           //skip


  //start the thread, so that the UpdateFunction will be called continously
	PRINT_INFO("Starting thread\n");
	if (dev->StartThread())
  {
		PRINT_ERROR("could not start thread\n");
		return -1;
	}


  //set the scan parameters
  if (dev->SetScanParams(scanName,scanStart, scanEnd, scanSkip, encoding, scanType)){
    PRINT_INFO("Error setting the scan parameters\n");
    exit(1);
  }


	double timeout_sec = 0.2;
  double time_stamp;

  vector< vector<unsigned int> > values;
  vector<double> timeStamps;


  //fill the lidarScan static values
  Magic::LidarScan lidarScan;
  lidarScan.ranges.size = nPoints;
  lidarScan.ranges.data = new float[lidarScan.ranges.size];
  lidarScan.startAngle  = -135.0/180.0*M_PI;;
  lidarScan.stopAngle   = 135.0/180.0*M_PI;;
  lidarScan.angleStep   = 0.25/180.0*M_PI;
  lidarScan.counter     = 0;
  lidarScan.id          = 0;

  HeartBeat hbeat;
  hbeat.sender  = (char*)"runHokuyo";
  hbeat.msgName = (char*)lidarScanMsgName.c_str();
  hbeat.status  = 0;

  //capture CTRL-C for proper shutdown
  signal(SIGINT,ShutdownFn);

  while(1)
  {
    if (dev->GetValues(values,timeStamps,timeout_sec) == 0)
    {
      int numPackets = values.size();
      //printf("num packets = %d\n",numPackets);
      for (int j=0; j<numPackets; j++)
      {
        time_stamp = timeStamps[j];
        
        //copy ranges
        vector<unsigned int> & ranges = values[j];
        
        //fill the LidarScan packet
        lidarScan.startTime = lidarScan.stopTime = time_stamp;
        lidarScan.counter++;
        
        float * rangesF = lidarScan.ranges.data;
        for (int jj=0;jj<lidarScan.ranges.size; jj++)
          *rangesF++ = (float)ranges[jj]*0.001;


        //publish messages
        IPC_publishData(lidarScanMsgName.c_str(),&lidarScan);

        //publis heart beat message
        hbeat.t = Timer::GetAbsoluteTime();
        IPC_publishData(hbeatMsgName.c_str(),&hbeat);

        printf(".");fflush(stdout);
      }
    }

    else
    {
      PRINT_ERROR("could not get values (timeout)\n");
    }
  } 

  return 0;
}
