#ifndef __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#include "IPCMailboxes.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#include <Vis/IPCMailboxes.hh>
#endif

#include "MagicPose.hh"

#define VIS_PLUGIN MagicPose2VisPose3D

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

    private: IPCMailbox * magicPoseMailbox;
    private: string poseMsgName;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->magicPoseMailbox = NULL;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
VIS_PLUGIN::~VIS_PLUGIN()
{
  DELETE_IF_NOT_NULL(this->magicPoseMailbox);
}

////////////////////////////////////////////////////////////////////////////////
// Load the configuration from xml file
void VIS_PLUGIN::LoadPlugin()
{
  this->poseMsgName = this->node->GetString("msgName","",REQUIRED);
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  //initialize the mailboxes
  this->magicPoseMailbox = new IPCMailbox(this->poseMsgName);
  if ( this->magicPoseMailbox->Subscribe() )
    vthrow("could not subscribe to a mailbox");

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
  //update pose
  if (this->magicPoseMailbox->IsFresh())
  {
    //pointer to the data structure    
    Magic::Pose * mpose = (Magic::Pose*)this->magicPoseMailbox->GetData();
    
    //set position
    this->parentPlugin->SetXYZ(mpose->x,mpose->y,mpose->z);
    
    //set orientation
    this->parentPlugin->SetRPY(mpose->roll,mpose->pitch,mpose->yaw);

  }
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


