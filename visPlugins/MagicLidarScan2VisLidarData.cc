#include "VisPlugin.hh"
#include "IPCMailboxes.hh"
#include "Lidar2DVisual.hh"
#include "MagicSensorDataTypes.hh"

#define VIS_PLUGIN MagicLidarScan2VisLidarData

namespace vis
{
  class VIS_PLUGIN : public VisPlugin
  {
    /// \brief Constructor
    public: VIS_PLUGIN();
    
    /// \brief Destructor
    public: ~VIS_PLUGIN();

    /// \brief Load the configuration from xml file
    public: void LoadPlugin();

    /// \brief Initialize the plugin
    public: void InitializePlugin();

    /// \brief Shutdown the plugin
    public: void ShutdownPlugin();

    /// \brief Update the plugin
    public: void UpdatePlugin();

    private: IPCMailbox * lidarScanMailbox;
    private: string  lidarMsgName;

    private: vis::Lidar2DDataDouble lidarData;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->lidarScanMailbox = NULL;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
VIS_PLUGIN::~VIS_PLUGIN()
{
}

////////////////////////////////////////////////////////////////////////////////
// Load the configuration from xml file
void VIS_PLUGIN::LoadPlugin()
{
  this->lidarMsgName = this->node->GetString("msgName","",REQUIRED);
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  //initialize the mailboxes
  this->lidarScanMailbox = new IPCMailbox(this->lidarMsgName);
  if ( this->lidarScanMailbox->Subscribe() )
    vthrow("could not subscribe to a mailbox");

}

////////////////////////////////////////////////////////////////////////////////
// Shutdown the plugin
void VIS_PLUGIN::ShutdownPlugin()
{
  if (this->lidarScanMailbox) { delete this->lidarScanMailbox; this->lidarScanMailbox = NULL; }
}

////////////////////////////////////////////////////////////////////////////////
// Update the plugin
void VIS_PLUGIN::UpdatePlugin()
{
  //update pose
  if (this->lidarScanMailbox->IsFresh())
  {
    //pointer to the data structure
    Magic::LidarScan * lidarScan = (Magic::LidarScan*)this->lidarScanMailbox->GetData();

    if (this->parentPlugin->GetType().compare("Lidar2DVisual") == 0)
    {
      //allocate new memory if needed
      int size = lidarScan->ranges.size;
      if (size != this->lidarData.ranges.size)
      {
        this->lidarData.ranges.Resize(size);
        this->lidarData.angles.Resize(size);
        this->lidarData.direction = 1;

        //create the array of angles
        double * angles = &(this->lidarData.angles.data[0]);        
        

        double angle = lidarScan->startAngle;
        double res = lidarScan->angleStep;

        for (int ii=0; ii<size; ii++)
        {
          *angles++ = angle;
          angle += res;
        }

      }
      
      //copy the ranges
      double * dranges = &(this->lidarData.ranges.data[0]);
      float * franges  = &(lidarScan->ranges.data[0]);
      for (int ii=0; ii<size; ii++)
        *dranges++ = (double)*franges++;

      this->lidarData.timestamp = lidarScan->startTime;

      Lidar2DVisual * visual = (Lidar2DVisual*)this->parentPlugin;

      visual->SetLaserData(this->lidarData.ranges.data,
                           this->lidarData.angles.data,
                           this->lidarData.ranges.size,
                           this->lidarData.direction);
    }
  }
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


