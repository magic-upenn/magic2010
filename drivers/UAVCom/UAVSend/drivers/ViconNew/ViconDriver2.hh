/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#ifndef VICON_DRIVER2_HH
#define VICON_DRIVER2_HH

#include <list>
#include <string>
#include <pthread.h>
#include <sstream>
#include <signal.h>

#include "Client.h"


#define VICON_VERBOSE
#ifdef VICON_VERBOSE 
  #define VICON_LOG_INFO( msg )    { std::ostringstream msgStream; msgStream <<"["<<__FUNCTION__<<" : "<<__LINE__<<"] : "<< msg \
    << std::endl << std::flush; std::cout<<msgStream.str(); }
  #define VICON_LOG_ERROR( msg )    { std::ostringstream msgStream; msgStream <<"["<<__FUNCTION__<<" : "<<__LINE__<<"] : "<< msg \
    << std::endl << std::flush; std::cout<<msgStream.str(); }
#else
  #define VICON_LOG_INFO( msg )
  #define VICON_LOG_ERROR( msg )
#endif

struct ViconUnlabeledMarker
{
  double xyz[3];
};

struct ViconLabeledMarker
{
  std::string name;
  double      xyz[3];
  int         visible;  //1 for visible, 0 for occluded
};

struct ViconSubjectPose3D
{
  double    xyz[3];
  double    rpy[3];
  double    quat[4];
  double    rot[9];
  
  int       visible;

  int       validXyz;
  int       validRpy;
  int       validQuat;
  int       validRot;
};

struct ViconLatencyInfo
{
  double delivered;
  double processed;
  double datastream;
  double total;
};

struct ViconSubject
{
  std::string                      name;
  ViconSubjectPose3D               pose;
  std::list<ViconLabeledMarker>    markers;
};

struct ViconData
{
  int                              frameCntr;
  double                           unixTime;
  ViconLatencyInfo                 latencyInfo;
  std::list<ViconSubject>          subjects;
  std::list<ViconUnlabeledMarker>  unlabeledMarkers;
};

class ViconDriver2
{
  public:  ViconDriver2();
  public: ~ViconDriver2();
  
  public: int Connect(std::string host);
  public: int Disconnect();
  public: inline int IsConnected() { return this->connected; }

  public: int GetViconData(std::list<ViconData> & data);
  
  protected: int StartThread();
  protected: int StopThread();
  protected: int ParseSubjects(std::list<ViconSubject> & subjects);
  protected: int ParseUnlabeledMarkers(std::list<ViconUnlabeledMarker> & markers);
  protected: int ParseLatencyInfo(ViconLatencyInfo & info);
  protected: int PushViconData(ViconData & data);
  
  protected: int PrintSubjects();
  protected: int PrintUnlabeledMarkers();
  protected: int PrintLatency();
  
  protected: void LockDataMutex();
  protected: void UnlockDataMutex();

  protected: std::list<ViconData> viconData;
  protected: unsigned int         maxBufferedPackets; //maximum number of buffered data entries
    
  protected: static void         *ThreadFunc(void * input);
  protected: pthread_t            thread;
  protected: int                  connected;
  protected: int                  threadRunning;
  protected: pthread_mutex_t      dataMutex;
  
  protected: ViconDataStreamSDK::CPP::Client viconClient;
};

using namespace ViconDataStreamSDK::CPP;

namespace
{
  std::string Adapt( const bool i_Value )
  {
    return i_Value ? "True" : "False";
  }

  std::string Adapt( const Direction::Enum i_Direction )
  {
    switch( i_Direction )
    {
      case Direction::Forward:
        return "Forward";
      case Direction::Backward:
        return "Backward";
      case Direction::Left:
        return "Left";
      case Direction::Right:
        return "Right";
      case Direction::Up:
        return "Up";
      case Direction::Down:
        return "Down";
      default:
        return "Unknown";
    }
  }
}
#endif
