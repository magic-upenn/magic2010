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
  tempNode->attachObject( ent );
  ent->setQueryFlags(0);

  double dx=0.33;
  double dy=0.215;

  double wheelOffsets[3][4] = { {dx,dx,0,0},
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

/*
  



  //const double scale = 0.007;
  //tempNode->setScale(scale,scale,scale);
  //tempNode->pitch((Ogre::Radian)M_PI/2);
  tempNode->yaw((Ogre::Radian)M_PI/2);
  tempNode->setPosition(0,0,0);
  ent->setCastShadows(false);

  stringstream ss;

  const double dx1 = 0.16;
  const double dx2 = 0.008;
  const double dx3 = -0.15;
  const double dy1 = 0.13;
  const double dy2 = 0.16;
  const double dz = 0.0;
  double legOffsets[3][6] = { {dx1, dx2, dx3, dx1, dx2, dx3}, 
                                {-dy1, -dy2, -dy1, dy1, dy2, dy1}, 
                                {dz, dz,  dz,  dz, dz, dz} };

  for (int ii=0; ii<6; ii++)
  {
    ss<<this->id << "_leg_node" <<ii;
    Ogre::SceneNode * legNode = this->sceneNode->createChildSceneNode( ss.str() );

    ss.str(""); ss<<this->id << "_leg_node_temp" <<ii;
    Ogre::SceneNode * legTempNode = legNode->createChildSceneNode( ss.str() );

    ss.str(""); ss<<this->id<<"_leg_ent"<<ii;
    Ogre::Entity * legEnt = sceneMgr->createEntity( ss.str() , "rdk_leg.mesh" );
    
    legTempNode->attachObject( legEnt );
    legTempNode->setPosition(0, -0.045, -0.0282);
  
    legNode->setPosition(legOffsets[0][ii],legOffsets[2][ii],-legOffsets[1][ii]);
    legNode->yaw((Ogre::Radian)RDK_LEG_DEF_YAW);    

    this->legSceneNodes.push_back(legNode);
  }

*/  //initiliaze the mailboxes
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


