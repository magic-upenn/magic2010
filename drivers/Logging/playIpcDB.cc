#include "DataPlaybackDB.hh"
#include "ErrorMessage.hh"
#include "IpcHelper.hh"
//#include "PlaybackController.hh"

#include <iostream>
#include <stdlib.h>
#include <getopt.h>
#include <ipc.h>
#include <fcntl.h>
#include <termios.h>

using namespace std;
using namespace Upenn;

double seekTime   = -1;
double seekStart  = -1;
double timestamp  = 0;
double playOffset = 0;
double playSpeed  = 1.0;
char * filename   = NULL;
char * ipcHost    = (char*)"localhost";


int PrintUsage()
{
  printf("Usage flags:\n");
  printf("  -h, --help      : print this message\n");
  printf("  -f, --filename  : log file name without any extensions (required)\n");
  printf("  -s, --speed     : set the playback speed\n");
  printf("  -x, --seekUnix  : set the seek time (unix time)\n");
  printf("  -t, --seekStart : set the seek time (relative to the start of the log)\n");
  printf("  -o, --offset    : set the playback offset (relative)\n"); 

  return -1;
}

int ParseInputArgs(int argc, char **argv)
{
  int ch;
  char * flags = (char*)("ho:s:x:f:t:");

  static struct option long_options[] =
  {
    {"help", no_argument, 0, 'h'},
    {"speed", required_argument, 0, 's'},
    {"seekUnix", required_argument, 0, 'x'},
    {"seekStart",required_argument, 0, 't'},
    {"offset", required_argument, 0, 'o'},
    {"filename", required_argument, 0, 'f'},
    {0, 0, 0, 0}
  };

  int option_index = 0;



  //while ((ch = getopt(argc, argv, flags)) != -1)
  while ((ch = getopt_long(argc, argv, flags, long_options, &option_index)) != -1)
  {
    switch (ch)
    {
      case '?':
        printf("bad command-line options\n");
        break;
      case 'h':
        PrintUsage();
        exit(0);
      case 'o':
        playOffset = atof(optarg);
        break;
      case 's':
        playSpeed = atof(optarg);
        break;
      case 'f':
        filename = optarg;
        break;
      case 'k':
        seekTime = atof(optarg);
        break;
      case 't':
        seekStart = atof(optarg);
        break;
        
      default:
        printf("option %s\n", long_options[option_index].name);
        break;
    }
  }


  if (filename == NULL)
  {
    printf("please provide the log file name with --filename option\n");
    PrintUsage();
    exit(1);
  }
  printf("Playback parameters:\n Speed = %f\n Seek time = %f\n Offset = %f\n Filename = %s\n",playSpeed,seekTime,playOffset,filename);

  return 0;
}


int main(int argc, char **argv)
{
  char * data       = NULL;
  int dataLen       = 0;
  
  string info;

  ParseInputArgs(argc,argv);
  
  IPC_connectModule(IpcHelper::GetProcessName("IpcPlaybackDB").c_str(), "localhost");

  DataPlaybackDB pb;
  if (pb.Open(filename))
  {
    PRINT_ERROR("could not open log file with name "<<filename<<"\n");
    return -1;
  }
  
  //parse the header for message names
  ifstream & header = pb.GetHeader();
  vector<string> msgNames;
  
  string line;
  getline(header,line);
  if( header.fail() )
  {
    PRINT_ERROR("could not read line\n");
    return -1;
  }
  
  //extract the message names from the header
  while (true)
  {
    size_t pos = line.find("MSG_TYPE");
    if (pos != string::npos)
      msgNames.push_back(line.substr(pos+sizeof("MSG_TYPE")));

    getline(header,line);
    if( header.fail() )
    {
      break;
    }
  }

  int nMsgs = msgNames.size();
  PRINT_INFO("loaded message names:\n");
  for (int ii=0; ii<nMsgs; ii++)
    PRINT_INFO(msgNames[ii]<<"\n");

  double currTime = Upenn::Timer::GetAbsoluteTime();

  pb.SetPlayOffset(playOffset);
  pb.SetPlaySpeed(playSpeed);

  int cntr=0;

/*
  PlaybackController playController;
  PlaybackControlData controlData;

  if (playController.Connect())
  {
    PRINT_ERROR("playback controller could not connect\n");
    return -1;
  }


  while (!playController.IsFresh())
    IPC_listenWait(10);

  if (playController.GetControls(&controlData))
  {
    PRINT_ERROR("could not get playback control data\n");
    return -1;
  }

  seekTime = controlData.seekTime;
*/


  if (fcntl(0, F_SETFL, O_NONBLOCK))
  {
    PRINT_ERROR("could not set non-blocking input\n");
    return -1;
  }
  
  
  struct termios oldterm,newterm;
  
  //get current port settings
  if( tcgetattr( 0, &oldterm ) < 0 )
  {
    PRINT_ERROR("Unable to get serial port attribute\n");
    return -1;
  }
  
  newterm=oldterm;

  //cfmakeraw initializes the port to standard configuration. Use this!
  cfmakeraw( &newterm );
  
  //set new attributes 
  if( tcsetattr( 0, TCSAFLUSH, &newterm ) < 0 )
  {
    PRINT_ERROR("Unable to set serial port attributes\n");
    return -1;
  }

  char c;
  int nChars;


  if (seekStart > 0)
    seekTime = pb.GetLogStartTime() + seekStart;

  while(1)
  {
    if (playSpeed > 0.01)
    {
      currTime = Upenn::Timer::GetAbsoluteTime();
      if (pb.GetData(&data,dataLen,timestamp,info,seekTime))
      {
        PRINT_ERROR("could not get data (reached the end?)\n");
        PRINT_INFO("exiting\n");
        //set new attributes 
        if( tcsetattr( 0, TCSAFLUSH, &oldterm ) < 0 )
        {
          PRINT_ERROR("Unable to set serial port attributes\n");
          return -1;
        }
        return 0;
      }
      
      //set the seek time to -1 so that we dont seek any more and just
      //continue to playback in order
      seekTime = -1;

      //printf("got msg %s\n",info.c_str());
      //printf("curr time: %f, des time: %f\n",currTime,timestamp);
      //printf("."); fflush(stdout);
      double dt = timestamp - currTime;
      while(dt > 0)
      {
        if (dt > 0.1)
          dt = 0.1;
        usleep(dt*1000000);
        currTime = Upenn::Timer::GetAbsoluteTime();
        dt = timestamp - currTime;
      }
      
      if (IPC_publish(info.c_str(),dataLen,data) != IPC_OK)
      {
        PRINT_ERROR("could not publish data\n");
        return -1;
      }
    }
    else
      usleep(100000);
    
      
    nChars = read(0,&c,1);
    if (nChars==1)
    {
      //printf("got char : %c\n",c);
      switch (c)
      {
        case '=':
          playSpeed+=0.1;
          PRINT_INFO("Setting playback speed to "<<playSpeed<<"\r\n");
          pb.SetPlaySpeed(playSpeed);
          break;
        case '-':
          playSpeed-=0.1;
          if (playSpeed < 0.1)
            playSpeed = 0.0001;
          PRINT_INFO("Setting playback speed to "<<playSpeed<<"\r\n");
          pb.SetPlaySpeed(playSpeed);
          break;
          
        case 'r':   //reset the playback from the beginning
          PRINT_INFO("Resetting playback to original start point\r\n");
          seekTime = 0;
          break;
      
        case 'q':
          PRINT_INFO("exiting\n");
          //restore old terminal attributes 
          if( tcsetattr( 0, TCSAFLUSH, &oldterm ) < 0 )
          {
            PRINT_ERROR("Unable to set serial port attributes\n");
            return -1;
          }

          pb.Close();
          return 0;
      
        default:
          break;
      }
    }

    cntr++;
  }


  pb.Close();

  return 0;
}
