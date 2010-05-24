#ifndef MICRO_GATEWAY_HH
#define MICRO_GATEWAY_HH

#include "SerialDevice.hh"
#include "DynamixelPacket.h"
#include <vector>
#include <list>
#include "Timer.hh"
#include <ipc.h>
#include "MagicHostCom.hh"
#include "DynamixelController.hh"


#define MICRO_GATEWAY_SERIAL_INPUT_BUF_SIZE 1024
#define MICRO_GATEWAY_SERIAL_OUTPUT_BUF_SIZE 1024
#define MICRO_GATEWAY_ENCODER_UPDATE_TIME 0.025
#define MICRO_GATEWAY_RS485_RESPONSE_TIMEOUT 0.01

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
    
    //connect to the IPC network
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
    
    private: string DefineMsg(int id, int type, string msgName);
    private: string DefineMsg(string msgName, string format);
    private: int PublishMsg(string msgName, void * data);
    private: int SubscribeMsg(string msgName);
    private: int InitializeMessages();
    private: int IdType2Ind(int id, int type);
    private: int AddWaitFor485Response(int id, int type);
    private: int AddIdOn485Bus(int id);


    private: void static IpcMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);

    private: void static VelocityCmdMsgHandler (MSG_INSTANCE msgRef, 
                                      BYTE_ARRAY callData, void *clientData);
                                      
    private: int PrintSerialPacket(DynamixelPacket * dpacket);
    private: int SendRS485Queue();
    private: int PushRS485Queue(uint8_t * data, int size, bool wait, bool free);
    private: int PushRS485Queue(uint8_t id, uint8_t type, uint8_t * buf,
                                uint8_t size);
                                
    private: bool NeedToWaitForRS485Response(int id, int type);
    private: bool NeedToWaitForRS485Response(int index);
    private: bool NeedToWaitForRS485Response(uint8_t * dpacket);
    private: int  OnRS485Bus(int id);
    private: bool ValidId(int id);



    //dynamixel packet handlers
    private: int GpsPacketHandler(DynamixelPacket * dpacket);
    private: int MotorControllerPacketHandler(DynamixelPacket * dpacket);
    private: int ImuPacketHandler(DynamixelPacket * dpacket);
    private: int HandleSerialPacket(DynamixelPacket * dpacket);
    private: int RcPacketHandler(DynamixelPacket * dpacket);
    private: int ServoPacketHandler(DynamixelPacket * dpacket);
    private: int DynamixelControllerUpdate(int id, DynamixelPacket * dpacket);
    
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
    private: int * reggedMsgTypes;
    private: int * wait485Response;
    private: int * idsOn485Bus;
    private: vector<string> msgNames;
    private: bool waitingRS485Resp;
    private: Timer rs485timer;
    private: Timer imuTimer;
    private: Timer gpsTimer;
    private: Timer encoderTimer;
    private: string robotName;
    private: list<RS485QueueItem> RS485Queue;
    private: double encoderUpdateTime;
    private: vector<DynamixelController*> dynamixelControllers;
    private: vector<string> dynamixelIpcMsgNames;


    private: string gpsMsgName;
    private: string encMsgName;
  };
}
#endif

