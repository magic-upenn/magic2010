#ifndef __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#endif

#include "MagicHostCom.hh"
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
    
    private: void Simulate(double dt);
    
    double sx,sy,sz,svx,svy,svz,sv;
    double sroll,spitch,syaw,swroll,swpitch,swyaw;
    
    IPCMailbox * controlMailbox;
    string robotName;
    string encodersMsgName;
    Upenn::Timer timer0;

  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  x=y=z=vx=vy=vz=v=0;
  roll=pitch=yaw=wroll=wpitch=wyaw=0;
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
  this->sx     = this->x;
  this->sy     = this->y;
  this->sz     = this->z;
  this->sroll  = this->roll;
  this->spitch = this->pitch;
  this->syaw   = this->yaw;
  
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
// Shutdown the plugin
void VIS_PLUGIN::Simulate(double dt)
{


}

////////////////////////////////////////////////////////////////////////////////
// Update the plugin
void VIS_PLUGIN::UpdatePlugin()
{
  double dt = this->timer0.Toc();
  this->timer0.Tic();
  
  this->Simulate(dt);
  
  
  Magic::EncoderCounts counts;
  counts.fr = 0;
  counts.fl = 0;
  counts.rr = 0;
  counts.rl = 0;
  
  if (IPC_publishData(this->encodersMsgName.c_str(),&counts) != IPC_OK)
    vthrow("could not publish encoder message\n");
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


