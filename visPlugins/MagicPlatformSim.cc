#ifndef __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#include "IPCMailboxes.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#include <Vis/IPCMailboxes.hh>
#endif

#include "MagicHostCom.hh"
#include "VehicleDynamics2D.hh"
#include "Timer.hh"

#define VIS_PLUGIN MagicPlatformSimPlugin

#define MAGIC_PLATFORM_CONTROL_CMD_TIMOUT 0.1

using namespace Magic;

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
    
    VehicleDynamics2D * dyn;
    IPCMailbox * controlMailbox;
    string robotName;
    string encodersMsgName;
    Upenn::Timer timer0;
    Upenn::Timer cmdTimeoutTimer;

  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->dyn = new VehicleDynamics2D();
  this->controlMailbox = NULL;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
VIS_PLUGIN::~VIS_PLUGIN()
{
  if (this->dyn) delete this->dyn;
  if (this->controlMailbox) delete this->controlMailbox;
}

////////////////////////////////////////////////////////////////////////////////
// Load the configuration from xml file
void VIS_PLUGIN::LoadPlugin()
{
  this->dyn->SetXYZ(this->x,this->y,this->z);
  this->dyn->SetRPY(this->roll,this->pitch,this->yaw);
  
  this->robotName = this->node->GetString("robotName","",REQUIRED);
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  this->controlMailbox = new IPCMailbox(this->robotName + "/VelocityCmd");
  if ( this->controlMailbox->Subscribe() )
    vthrow("could not subscribe to a mailbox");
 
    
  this->encodersMsgName = this->robotName + "/Encoders";
  if (IPC_defineMsg(this->encodersMsgName.c_str(),IPC_VARIABLE_LENGTH,
                Magic::EncoderCounts::getIPCFormat()) != IPC_OK)
    vthrow("could not define output pose message\n");
    
  this->timer0.Tic();
  this->cmdTimeoutTimer.Tic();
}

////////////////////////////////////////////////////////////////////////////////
// Shutdown the plugin
void VIS_PLUGIN::ShutdownPlugin()
{


}


////////////////////////////////////////////////////////////////////////////////
// Update the plugin
void VIS_PLUGIN::UpdatePlugin()
{
  if (this->controlMailbox->IsFresh())
  {
    VelocityCmd * cmd = (VelocityCmd*)this->controlMailbox->GetData();
    this->dyn->SetDesVW(cmd->v,cmd->w);
    this->cmdTimeoutTimer.Tic();
  }

  double cmdAge = this->cmdTimeoutTimer.Toc();
  if (cmdAge > MAGIC_PLATFORM_CONTROL_CMD_TIMOUT)
  {
    this->dyn->SetDesVW(0,0);
    this->cmdTimeoutTimer.Tic();
  }

  double dt = this->timer0.Toc();
  this->timer0.Tic();

  this->dyn->Simulate(dt);
  
  
  Magic::EncoderCounts counts;
  this->dyn->GetCounts(&counts);
  
  if (IPC_publishData(this->encodersMsgName.c_str(),&counts) != IPC_OK)
    vthrow("could not publish encoder message\n");

  double x,y,z;
  double roll,pitch,yaw;
  this->dyn->GetXYZ(x,y,z);
  this->dyn->GetRPY(roll,pitch,yaw);
  this->parentPlugin->SetXYZ(x,y,z);
  this->parentPlugin->SetRPY(roll,pitch,yaw);
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


