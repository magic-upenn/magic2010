#ifndef __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#include "IPCMailboxes.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#include <Vis/IPCMailboxes.hh>
#endif

#include "MagicSensorDataTypes.hh"

#define VIS_PLUGIN MagicServoState2VisPose

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

    private: IPCMailbox * servoStateMailbox;
    private: string servoMsgName;
    private: double offsetd;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->servoStateMailbox = NULL;
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
  this->servoMsgName = this->node->GetString("msgName","",REQUIRED);
  this->offsetd      = this->node->GetDouble("offsetd",0,NOT_REQUIRED)/180.0*M_PI;
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  //initialize the mailboxes
  this->servoStateMailbox = new IPCMailbox(this->servoMsgName);
  if ( this->servoStateMailbox->Subscribe() )
    vthrow("could not subscribe to a mailbox");

}

////////////////////////////////////////////////////////////////////////////////
// Shutdown the plugin
void VIS_PLUGIN::ShutdownPlugin()
{
  if (this->servoStateMailbox) { delete this->servoStateMailbox; this->servoStateMailbox = NULL; }
}

////////////////////////////////////////////////////////////////////////////////
// Update the plugin
void VIS_PLUGIN::UpdatePlugin()
{
  //update pose
  if (this->servoStateMailbox->IsFresh())
  {
    //pointer to the data structure
    Magic::ServoState * servoState = (Magic::ServoState*)this->servoStateMailbox->GetData();
    this->parentPlugin->SetYaw(servoState->position + this->offsetd);
  }
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


