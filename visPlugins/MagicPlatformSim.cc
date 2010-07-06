#include "VisPlugin.hh"
#include "IPCMailboxes.hh"

#include "MagicHostCom.hh"
#include "VehicleDynamics2D.hh"
#include "MagicPose.hh"
#include "Timer.hh"

#define VIS_PLUGIN MagicPlatformSimPlugin

#define MAGIC_PLATFORM_CONTROL_CMD_TIMOUT 0.2

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
    
    private: Upenn::Timer timer0;
    private: Upenn::Timer cmdTimeoutTimer;
    private: VehicleDynamics2D * dyn;
    private: IPCMailbox * controlMailbox;

    private: string robotName;
    private: string encodersMsgName;
    private: string imuMsgName;
    private: string truthMsgName;

    private: bool publishTruth;
    private: int id;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->dyn            = new VehicleDynamics2D();
  this->controlMailbox = NULL;
  this->publishTruth   = false;
  this->id             = 0;
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
  
  this->robotName      = this->node->GetString("robotName","",REQUIRED);
  this->truthMsgName   = this->node->GetString("truthMsgName","",NOT_REQUIRED);
  if (!this->truthMsgName.empty())
    this->publishTruth = true;

  this->id             = this->node->GetInt("id",0,NOT_REQUIRED);
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
    vthrow("could not define output pose message");

  if (this->publishTruth)
  {
    if (IPC_defineMsg(this->truthMsgName.c_str(), IPC_VARIABLE_LENGTH,
                Magic::Pose::getIPCFormat()) != IPC_OK)
      vthrow("could not define thruth pose message")
  }

  this->imuMsgName = this->robotName + "/ImuFiltered";
  if (IPC_defineMsg(this->imuMsgName.c_str(),IPC_VARIABLE_LENGTH,
                Magic::ImuFiltered::getIPCFormat()) != IPC_OK)
    vthrow("could not define output pose message");
    
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

  //update the position of the visualization
  double x,y,z;
  double roll,pitch,yaw;
  this->dyn->GetXYZ(x,y,z);
  this->dyn->GetRPY(roll,pitch,yaw);
  this->parentPlugin->SetXYZ(x,y,z);
  this->parentPlugin->SetRPY(roll,pitch,yaw);


  //send out truth message if needed
  if (this->publishTruth)
  {
    Magic::Pose mpose(x,y,z,0,0,roll,pitch,yaw,this->timer0.GetAbsoluteTime(),this->id);
    if (IPC_publishData(this->truthMsgName.c_str(),&mpose) != IPC_OK)
      vthrow("could not publish thruth message\n");
  }

  double wroll,wpitch,wyaw;
  this->dyn->GetWRPY(wroll,wpitch,wyaw);
  Magic::ImuFiltered imu;
  imu.roll   = roll;
  imu.pitch  = pitch;
  imu.yaw    = yaw;
  imu.wroll  = wroll;
  imu.wpitch = wpitch;
  imu.wyaw   = wyaw;
  imu.t      = Upenn::Timer::GetAbsoluteTime();

  if (IPC_publishData(this->imuMsgName.c_str(),&imu) != IPC_OK)
    vthrow("could not publish imu message\n");
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


