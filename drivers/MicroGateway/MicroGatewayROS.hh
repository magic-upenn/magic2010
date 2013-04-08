#ifndef MICRO_GATEWAYROS_HH
#define MICRO_GATEWAYROS_HH

#include "SerialDevice.hh"
#include "DynamixelPacket.h"
#include <vector>
#include <list>
#include "Timer.hh"
#include <ipc.h>
#include "MagicHostCom.hh"
#include "MagicSensorDataTypes.hh"

//ROS stuff
#include <ros/ros.h>
#include <tf/transform_broadcaster.h>
#include <nav_msgs/Odometry.h>


#define MICRO_GATEWAY_SERIAL_INPUT_BUF_SIZE 1024
#define MICRO_GATEWAY_SERIAL_OUTPUT_BUF_SIZE 1024
#define MICRO_GATEWAY_ENCODER_UPDATE_TIME 0.025
#define MICRO_GATEWAY_RS485_RESPONSE_TIMEOUT 0.1

#define SERVO1_MIN_LIMIT_DEG -40
#define SERVO1_MAX_LIMIT_DEG  40

namespace Upenn
{

  struct RS485QueueItem
  {
    uint8_t * data;
    int size;
    bool wait;
    bool free;
  };

  class MicroGateway
  {
    public: MicroGateway();
    public: ~MicroGateway();
    
    //connect to the Serial bus via USB
    public: int ConnectSerial(char * dev, int baudRate);
    
    //connect to ROS Master
    public: int ConnectROS(char * addr = (char*)"localhost"); 

    //connect to IPC central
    public: int ConnectIPC(char * addr = (char*)"localhost");
    
    
    //wrap the data into Dynamixel packet and send
    private: int WrapAndSendDataToBus(uint8_t id, uint8_t type,
                                  uint8_t * buf, uint16_t size);
    
    //wrap the data into Dynamixel packet
    private: int WrapData(uint8_t id, uint8_t type,
                          uint8_t * inbuf, uint16_t insize,
                          uint8_t * outpuf, uint16_t outsize);
    
    //send the data out to the Serial bus
    public: int SendSerialPacket(uint8_t id, uint8_t type, 
                            uint8_t * buf, uint8_t size);
                            
    public: int SendSerialPacket(uint8_t * buf, uint8_t size);
    
    //send the data out to the IPC network
    public: int SendIPC(uint8_t * buf, uint16_t size);
    
    //receive dat from serial bus
    public: int ReceiveSerialPacket(DynamixelPacket * dpacket, double timeoutSec);

    public: int ProcessSerialPacket(DynamixelPacket * dpacket);

    public: int Main();

    public: int ReadPacket(DynamixelPacket * dpacket, double timeout);
    public: int SwitchModeConfig();
    public: int SwitchModeRun();
    public: int WriteConfig(uint16_t offset, uint8_t * data, uint16_t size);
    public: int ReadConfig(uint16_t offset, uint8_t * data, uint16_t size);
    
    private: string DefineMsg(string msgName, string format);
    private: int PublishMsg(string msgName, void * data);
    private: int SubscribeMsg(string msgName);
    private: int InitializeMessages();
    private: int IdType2Ind(int id, int type);
    private: int AddWaitFor485Response(int id, int type);
    private: int AddIdOn485Bus(int id);


    //messages coming from IPC
    private: void static VelocityCmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);

    private: void static Laser0CmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);

    private: void static XbeeForwardMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);

    private: void static ServoControllerCmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);
                                      
    private: int PrintSerialPacket(DynamixelPacket * dpacket);

    private: bool ValidId(int id);

    private: int ResetImu();



    //dynamixel packet handlers (incoming from microcontroller)
    private: int GpsPacketHandler(DynamixelPacket * dpacket);
    private: int MotorControllerPacketHandler(DynamixelPacket * dpacket);
    private: int ImuPacketHandler(DynamixelPacket * dpacket);
    private: int HandleSerialPacket(DynamixelPacket * dpacket);
    private: int RcPacketHandler(DynamixelPacket * dpacket);
    private: int ServoPacketHandler(DynamixelPacket * dpacket);
    private: int EstopPacketHandler(DynamixelPacket * dpacket);
    private: int MasterPacketHandler(DynamixelPacket * dpacket);
    private: int MainControllerPacketHandler(DynamixelPacket * dpacket);
    private: int XbeePacketHandler(DynamixelPacket * dpacket);
    
    private: SerialDevice * sd;
    private: bool connectedSerial;
    private: bool connectedIPC;
    private: uint8_t * inBufSerial;
    private: uint8_t * outBufSerial;
    private: uint16_t inBufSerialSize;
    private: uint16_t outBufSerialSize;
    private: uint16_t inNumBufferedSerial;
    private: uint8_t * inBufSerialPos;
    private: int robotId;
    private: vector<string> msgNames;
    private: Timer imuTimer;
    private: Timer gpsTimer;
    private: Timer encoderTimer;
    private: string robotName;


    private: string gpsMsgName;
    private: string encMsgName;
    private: string imuMsgName;
    private: string imuRawMsgName;
    private: string estopMsgName;
    private: string selectedIdMsgName;
    private: string servo1StateMsgName;
    private: string batteryStatusMsgName;
    private: string motorStatusMsgName;
    private: string xbeeMsgName;

    private: int vCmdPrev;
    private: int wCmdPrev;

    //ROS stuff
    private: ros::NodeHandle *nh; 
    private: ros::Publisher odom_pub; 
    private: ros::Subscriber vel_sub; 
    private: tf::TransformBroadcaster odom_broadcaster; 
    private: nav_msgs::Odometry odom_;

    private: double wheelSeparation;
    private: double wheelDiameter;
    private: double torque;
    private: double wheelSpeed[2];
    private: double odomPose[3];
    private: double odomVel[3];

    //private: boost::mutex lock;
    private: double x_;
    private: double rot_;
    //private: bool alive_;

    private: ros::Time last_time; 
    private: bool connectedROS; 

    // Custom Callback Queue
    //private: ros::CallbackQueue queue_;
    //private: boost::thread callback_queue_thread_;
    //private: void QueueThread();

    //private: virtual void UpdateChild(); 
    //private: virtual void FiniChild(); 
    //private: void GetPositionCmd(); 

    //major ROS functions
    private: void ROSCalcOdom(Magic::EncoderCounts encPacket); 
    private: void cmdVelCallback(const geometry_msgs::Twist::ConstPtr& cmd_msg); //double x, double rot);
    
  };
}
#endif

