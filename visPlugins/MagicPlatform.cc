#include "VisPlugin.hh"
#include "IPCMailboxes.hh"

#include "MagicSensorDataTypes.hh"

#include <sstream>
#include <vector>

#define VIS_PLUGIN MagicPlatformPlugin


using namespace vis;
using namespace std;
using namespace gazebo;

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

    private: IPCMailbox * pose3DMailbox;
    private: IPCMailboxQueue * encodersMailbox;
    private: std::vector<Ogre::SceneNode*> wheelNodes;
  };
}



////////////////////////////////////////////////////////////////////////////////
// Constructor
VIS_PLUGIN::VIS_PLUGIN()
{
  this->pose3DMailbox      = NULL;
  this->encodersMailbox    = NULL;
}

////////////////////////////////////////////////////////////////////////////////
// Destructor
VIS_PLUGIN::~VIS_PLUGIN()
{
  DELETE_IF_NOT_NULL(this->pose3DMailbox);
  DELETE_IF_NOT_NULL(this->encodersMailbox);
}

////////////////////////////////////////////////////////////////////////////////
// Load the configuration from xml file
void VIS_PLUGIN::LoadPlugin()
{
  
}

////////////////////////////////////////////////////////////////////////////////
// Initialize the plugin
void VIS_PLUGIN::InitializePlugin()
{
  
  Ogre::Entity * ent = sceneMgr->createEntity( id + "_body" , "magic2010_base.mesh" );
  Ogre::SceneNode * tempNode = this->sceneNode->createChildSceneNode(this->id + "_temp");
  tempNode->setPosition(-0.165,0,0);
  tempNode->attachObject( ent );
  ent->setQueryFlags(0);

  double dx=0.33;
  double dy=0.215;

  double wheelOffsets[3][4] = { {dx-0.165,dx-0.165,-0.165,-0.165},
                                {0,0,0,0},
                                {dy, -dy, dy, -dy} 
                                 };

  double wheelPitch[4] = {0,M_PI,0,M_PI};

  stringstream ss;

  for (int ii=0; ii<4; ii++)
  {
    ss.str("");
    ss<<this->id<<"_wheel"<<ii;
    Ogre::SceneNode * wheelNode = this->sceneNode->createChildSceneNode(ss.str());
    Ogre::Entity * wheelEnt = sceneMgr->createEntity( ss.str() , "magic2010_wheel.mesh" );
    wheelEnt->setQueryFlags(0);
    wheelNode->attachObject(wheelEnt);
    wheelNode->setPosition(wheelOffsets[0][ii],wheelOffsets[1][ii],wheelOffsets[2][ii]);
    wheelNode->pitch((Ogre::Radian)wheelPitch[ii]);
    this->wheelNodes.push_back(wheelNode);
  }

  //initiliaze the mailboxes
  this->pose3DMailbox = new IPCMailbox(id + POSE_3D_MAILBOX_SUFFIX);
  this->encodersMailbox = new IPCMailboxQueue(id + "/Encoders");
  
  if ( this->pose3DMailbox->Subscribe() || this->encodersMailbox->Subscribe() )
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
  //check pose mailbox
  if (this->pose3DMailbox->IsFresh())
  {
    //pointer to the data structure    
    vis::Pose3D * pose=(vis::Pose3D *)this->pose3DMailbox->GetData();
    
    //set position
    this->SetXYZ(pose->pos.x,pose->pos.y,pose->pos.z);
    
    //set orientation
    this->SetRPY(pose->rot.roll,pose->rot.pitch,pose->rot.yaw);

  }

  while (this->encodersMailbox->IsFresh())
  {
    Magic::EncoderCounts * counts = (Magic::EncoderCounts *)this->encodersMailbox->GetData();
    this->wheelNodes[0]->roll(-(Ogre::Degree)counts->fr * 2.0);
    this->wheelNodes[1]->roll((Ogre::Degree)counts->fl * 2.0);
    this->wheelNodes[2]->roll(-(Ogre::Degree)counts->rr * 2.0);
    this->wheelNodes[3]->roll((Ogre::Degree)counts->rl * 2.0);
  }
}


using namespace std;
extern "C" VisPlugin * GetInstance();

VisPlugin * GetInstance()
{
  return new VIS_PLUGIN();
}


