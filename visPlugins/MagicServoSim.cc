#include "VisPlugin.hh"
#include "Servo1DSim.hh"
#include "MagicSensorDataTypes.hh"
#include "Timer.hh"
#include "ipc.h"
#include "IPCMailboxes.hh"

#define VIS_PLUGIN MagicServoSimPlugin

#define SERVO_DEF_MIN_ANGLE -20
#define SERVO_DEF_MAX_ANGLE  20
#define SERVO_DEF_SPEED      20
#define SERVO_DEF_IPC_MSG_SUFFIX "_servoState"
#define SERVO_DEF_CMD_MSG_NAME "Robot0/Servo1Cmd"

using namespace Upenn;
using namespace Magic;

namespace vis
{
  enum { SERVO_STATE_UNINITIALIZED, 
         SERVO_STATE_INITIALIZED,
         SERVO_STATE_MOVE_CMD_SENT,    
         SERVO_STATE_STOPPED
       };
         
  enum { SERVO_MODE_POINT,
         SERVO_MODE_SERVO
       };

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
    private: float maxSpeed;
    private: float maxAccel;
    private: string ipcMsgName;
    private: bool publishState;
    
    private: IPCMailbox * cmdMailbox;
    private: std::string cmdMsgName;
    private: int mode;
  };
}

using namespace vis;
using namespace std;
using namespace gazebo;

////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->servoSim        = NULL;
  this->state           = SERVO_STATE_UNINITIALIZED;
  this->dir             = 1;
  this->target          = 0;
  this->reversePoint    = 0.80;
  this->cmdMailbox      = NULL;
  this->maxSpeed        = SERVO_1D_SIM_DEF_MAX_SPEED;
  this->maxAccel        = SERVO_1D_SIM_DEF_MAX_ACCEL;
  this->mode            = SERVO_MODE_POINT;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
VIS_PLUGIN::~VIS_PLUGIN()
{
  DELETE_IF_NOT_NULL(this->servoSim);
  DELETE_IF_NOT_NULL(this->cmdMailbox);
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
  this->cmdMsgName   = this->node->GetString("cmdMsgName",SERVO_DEF_CMD_MSG_NAME,0);
  
  string modeStr     = this->node->GetString("mode","point",0);
  if (modeStr.compare("point") == 0)
    this->mode = SERVO_MODE_POINT;
  else if (modeStr.compare("servo") == 0)
    this->mode = SERVO_MODE_SERVO;
  else
    vthrow("unknown servo mode : " << modeStr);

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
  
  this->cmdMailbox = new IPCMailbox(this->cmdMsgName);
  if ( this->cmdMailbox->Subscribe() )
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
  //check the cmd mailbox
  if (this->cmdMailbox->IsFresh())
  {
    printf("got cmd\n");
    ServoControllerCmd * cmd = (ServoControllerCmd*)this->cmdMailbox->GetData();
    switch (cmd->mode)
    {
      case SERVO_MODE_POINT:
        this->target          = cmd->minAngle;
      case SERVO_MODE_SERVO:
        this->maxSpeed        = cmd->speed;
        this->maxAccel        = cmd->acceleration;
        this->minAngle        = cmd->minAngle;
        this->maxAngle        = cmd->maxAngle;
        this->mode            = cmd->mode;
        this->servoSim->SetMaxSpeed(this->maxSpeed);
        this->servoSim->SetMaxAccel(this->maxAccel);
        this->state           = SERVO_STATE_STOPPED;
        
        break;
      default:
        printf("WARNING: unknown cmd servo mode : %d\n",cmd->mode);
    }
  }


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

  if (this->mode == SERVO_MODE_POINT)
  {
    switch (this->state)
    {
      case SERVO_STATE_UNINITIALIZED:
      case SERVO_STATE_STOPPED:
      case SERVO_STATE_MOVE_CMD_SENT:
        if (this->servoSim->SetTarget(this->target))
          vthrow("could not set desired angle");

        this->state = SERVO_STATE_MOVE_CMD_SENT;
        break;
    }
  }
  
  else if (this->mode == SERVO_MODE_SERVO)
  {
    switch (this->state)
    {
      case SERVO_STATE_UNINITIALIZED:
      case SERVO_STATE_STOPPED:
        
        this->target = this->dir > 0 ? this->maxAngle : this->minAngle;
        if (this->servoSim->SetTarget(this->target))
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
}

using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


