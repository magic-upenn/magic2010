#ifndef  __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#include "IPCMailboxes.hh"
#include "VisInterfaces.hh"
#include "Lidar2D.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#include <Vis/IPCMailboxes.hh>
#include <Vis/VisInterfaces.hh>
#include <Vis/Lidar2D.hh>
#endif

#include "MagicSensorDataTypes.hh"
#include <string>
#include <vector>


namespace vis
{
  class MagicLidarScanPublisher : public VisPlugin
  {
    /// \brief Constructor
    public: MagicLidarScanPublisher();
    
    /// \brief Destructor
    public: ~MagicLidarScanPublisher();

    /// \brief Load the configuration from xml file
    public: void LoadPlugin();

    /// \brief Initialize the plugin
    public: void InitializePlugin();

    /// \brief Shutdown the plugin
    public: void ShutdownPlugin();

    /// \brief Update the plugin
    public: void UpdatePlugin();
    
    
    private: string ipcMsgName;
    private: vector<float>    ranges;
    private: vector<uint16_t> intensities;
    private: unsigned int counter;
  };
}

////////////////////////////////////////////////////////////////////////////////
// Constructor
MagicLidarScanPublisher::MagicLidarScanPublisher()
{
  this->counter       = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
MagicLidarScanPublisher::~MagicLidarScanPublisher()
{
}

////////////////////////////////////////////////////////////////////////////////
// Load the configuration from xml file
void MagicLidarScanPublisher::LoadPlugin()
{
  this->ipcMsgName = this->node->GetString("msgName","",REQUIRED);

  //check to make sure that the parent is a Lidar2D plugin
  if (this->parentPlugin->GetType().compare("Lidar2D") != 0)
    vthrow("parent plugin must be a Lidar2D");
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void MagicLidarScanPublisher::InitializePlugin()
{
  if (IPC_defineMsg(this->ipcMsgName.c_str(),IPC_VARIABLE_LENGTH,
                    Magic::LidarScan::getIPCFormat()) != IPC_OK)
      vthrow("could not define message");
}

////////////////////////////////////////////////////////////////////////////////
// Shutdown the plugin
void MagicLidarScanPublisher::ShutdownPlugin()
{
  
}

////////////////////////////////////////////////////////////////////////////////
// Update the plugin
void MagicLidarScanPublisher::UpdatePlugin()
{
  Lidar2D * lidar = (Lidar2D*)this->parentPlugin;
  Lidar2DDataDouble * lidarData = lidar->GetLidarData();
  if (lidarData)
  {
    if (lidarData->angles.size != lidarData->ranges.size)
      vthrow("number of ranges and angles is not equal");
    
    //resize the containers if needed
    if (this->ranges.size() < lidarData->ranges.size) 
      this->ranges.resize(lidarData->ranges.size);
      
    if (this->intensities.size() < lidarData->intensities.size) 
      this->intensities.resize(lidarData->intensities.size);
      
    //create pointers for fast array access
    double   * rangesIn  = lidarData->ranges.data;
    float    * rangesOut = &(this->ranges[0]);
    double   * intsIn    = lidarData->intensities.data;
    uint16_t * intsOut   = &(this->intensities[0]);
    
    //copy the values into the new data structure
    for (int ii=0; ii<lidarData->ranges.size; ii++)
      *rangesOut++ = *rangesIn++;
      
    for (int ii=0; ii<lidarData->intensities.size; ii++)
      *intsOut++ = *intsIn++;
    
    Magic::LidarScan scan;
    scan.ranges.size = lidarData->ranges.size;
    scan.ranges.data = &(this->ranges[0]);
    scan.intensities.size = lidarData->intensities.size;
    scan.intensities.data = &(this->intensities[0]);
    scan.id          = 0;
    scan.counter     = this->counter;
    scan.startAngle  = lidarData->angles.data[0];
    scan.angleStep   = fabs(lidarData->angles.data[1]-lidarData->angles.data[0]);
    scan.stopAngle   = lidarData->angles.data[lidarData->angles.size-1];
    scan.startTime   = lidarData->timestamp;
    scan.stopTime    = lidarData->timestamp;
    
    if (IPC_publishData(this->ipcMsgName.c_str(),&scan) != IPC_OK)
      vthrow("could not publish data");
    
    this->counter++;
  }
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new MagicLidarScanPublisher();
}
