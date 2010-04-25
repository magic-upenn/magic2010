#ifndef __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#endif

#include "MagicHostCom.hh"
#include "VehicleDynamics.hh"
#include "Timer.hh"

#define VIS_PLUGIN MagicPlatformSimPlugin

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
    
    VehicleDynamics * dyn;
    IPCMailbox * controlMailbox;
    string robotName;
    string encodersMsgName;
    Upenn::Timer timer0;

    double vDes,wDes;

  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->dyn = new VehicleDynamics();
  this->controlMailbox = NULL;
  this->vDes=0;
  this->wDes=0;
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
  
  this->robotName = this->node->GetString("robotName","",REQIRED);
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
    
  this->timer0->Tic();
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
    this->vDes = cmd->v;
    this->wDes = cmd->w;
    this->dyn->SetVW(this->vDes,this->wDes);
  }

  double dt = this->timer0.Toc();
  this->timer0.Tic();

  this->dyn->Simulate(dt);
  
  
  Magic::EncoderCounts counts;
  this->dyn->GetCounts(&counts);
  
  if (IPC_publishData(this->encodersMsgName.c_str(),&counts) != IPC_OK)
    vthrow("could not publish encoder message\n");
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


