#ifndef  __APPLE__
#include "VisPlugin.hh"
#include "VisError.hh"
#else
#include <Vis/VisPlugin.hh>
#include <Vis/VisError.hh>
#endif

#include "Servo1DSim.hh"
#include "MagicSensorDataTypes.hh"
#include "Timer.hh"
#include "ipc.h"

#define VIS_PLUGIN MagicServoSimPlugin

#define SERVO_DEF_MIN_ANGLE -20
#define SERVO_DEF_MAX_ANGLE  20
#define SERVO_DEF_SPEED      20
#define SERVO_DEF_IPC_MSG_SUFFIX "_servoState"

using namespace Upenn;
using namespace Magic;

namespace vis
{
  enum { SERVO_STATE_UNINITIALIZED, 
         SERVO_STATE_INITIALIZED,
         SERVO_STATE_MOVE_CMD_SENT,    
         SERVO_STATE_STOPPED};

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

    private: int cntr;
    private: Servo1DSim * servoSim;
    private: Ogre::Timer timer;
    private: int state;
    private: int dir;
    private: float minAngle;
    private: float maxAngle;
    private: float target;
    private: float reversePoint;
    private: float speed;
    private: string ipcMsgName;
    private: bool publishState;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->servoSim = NULL;
  this->state    = SERVO_STATE_UNINITIALIZED;
  this->dir      = 1;
  this->target   = 0;
  this->reversePoint = 0.80;
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
  this->minAngle     = this->node->GetDouble("minAngle",SERVO_DEF_MIN_ANGLE,0);
  this->maxAngle     = this->node->GetDouble("maxAngle",SERVO_DEF_MAX_ANGLE,0);
  this->speed        = this->node->GetDouble("speed",SERVO_DEF_SPEED,0);
  this->ipcMsgName   = this->node->GetString("msgName","",0);
  this->publishState = this->node->GetBool("publishState",false,0);

  if (this->ipcMsgName.empty())
    this->ipcMsgName = this->id + SERVO_DEF_IPC_MSG_SUFFIX;
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  this->servoSim = new Servo1DSim();
  this->servoSim->Reset(0,0);
  this->servoSim->SetMaxSpeed(this->speed);
  //this->servoSim->SetTarget(40);
  this->timer.reset();

  if (this->publishState)
  {
    if (IPC_defineMsg(this->ipcMsgName.c_str(), IPC_VARIABLE_LENGTH, 
                      ServoState::getIPCFormat()) != IPC_OK)
      vthrow("could not define message");
  }
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

  double dt = this->timer.getMilliseconds()*0.001;
  this->timer.reset();
  this->servoSim->Simulate(dt);
  
  double pos;
  if(this->servoSim->GetPos(pos))
    vthrow("could not get position");

  if (this->publishState)
  {
    ServoState state;
    state.position=pos * M_PI/180.0;
    state.velocity=0;
    state.acceleration=0;
    state.t = Upenn::Timer::GetAbsoluteTime();

    if (IPC_publishData(this->ipcMsgName.c_str(),(void*)&state) != IPC_OK)
      vthrow("could not publish data");
  }

  //printf("pos=%f\n",pos);

  this->SetYaw(pos/180.0*M_PI);

  switch (this->state)
  {
    case SERVO_STATE_UNINITIALIZED:
    case SERVO_STATE_STOPPED:
      
      this->target = this->dir > 0 ? this->maxAngle : this->minAngle;
      if (this->servoSim->SetTarget(target))
        vthrow("could not set desired angle");

      this->state = SERVO_STATE_MOVE_CMD_SENT;
      break;

    case SERVO_STATE_MOVE_CMD_SENT:

      if ((this->dir>0) && (pos > ( this->target * this->reversePoint)))
      {
        this->state = SERVO_STATE_STOPPED;
        this->dir*=-1;
      }

      else if ((this->dir<0) && (pos < ( this->target * this->reversePoint)))
      {
        this->state = SERVO_STATE_STOPPED;
        this->dir*=-1;
      }
      break;

    default:
      vthrow("unknown state");
  }
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


