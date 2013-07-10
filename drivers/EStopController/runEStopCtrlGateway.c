//******************
// standard includes
//******************
#include <stdlib.h>
#include <stdint.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/select.h>
#include <stdbool.h>

//************
// ipc include
//************
#include <ipc.h>

//**************************
// estop controller includes
//**************************
#include "VehicleMessages.h"
#include "VehicleInterface.h"
#include "EStopControllerDataType.h"

//******************
//device definitions
//******************

#define ESTOP_CONTROLLER_DEF_NAME "/dev/ttyACM0"
#define ESTOP_CONTROLLER_LOG_NAME "estopctrl"
#define ESTOP_CONTROLLER_BAUD_RATE 115200
#define GET_JOY vsc_get_stick_value
#define GET_BUT vsc_get_button_value

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

//*****************
// global variables
//*****************
VscInterfaceType* vscInterface;
uint16_t vscstatus=0;

char* gpsMsgName;
char* heartbeatMsgName;
char* feedbackMsgName;
char* joystickMsgName;
bool connectedIPC=false;
bool connectedSerial=false;

//********************************************************
// this function gets called when process halted by CTRL-C
//********************************************************
void exit_handler(int s) {  
        printf("Caught signal %d.\n",s);
        printf("Cleaning up VSC Interface...\n");
        vsc_cleanup(vscInterface);
        printf("Done cleaning.\n");
        exit(0);
}

/*****************/
//temporary subscription test
/*****************/
void JoystickReceiveHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
        EStopController * esc = (EStopController*)callData;

        printf("%i\t%i\t%i\t|\t%i\t%i\t%i\t|\t%u %u %u %u | %u %u %u %u\n",
               esc->leftX,esc->leftY,esc->leftZ,
               esc->rightX,esc->rightY,esc->rightZ,
               esc->bD,esc->bR,esc->bU,esc->bL,
               esc->b1,esc->b2,esc->b3,esc->b4);        

        IPC_freeByteArray(callData);
}
//**************************************************
// function to calculate difference in sampled times
//**************************************************
unsigned long diffTime(struct timespec start, struct timespec end, struct timespec *temp) {
        if ((end.tv_nsec - start.tv_nsec) < 0) {
                temp->tv_sec = end.tv_sec - start.tv_sec -1;
                temp->tv_nsec = 1000000000 + end.tv_nsec - start.tv_nsec;
        }
        else {
                temp->tv_sec = end.tv_sec - start.tv_sec;
                temp->tv_nsec = end.tv_nsec - start.tv_nsec;
        }
        return temp->tv_nsec;
}

//*************************
// IPC stuff
//*************************
int publishMsg(char * msgName, void * data) {
        if (IPC_publishData(msgName,data) != IPC_OK)
                return -1;
        return 0;
}

char* defineMsg(char* msgName, char* format) {
        // create message name //
        char* robotID=getenv("ROBOT_ID");

        if (robotID==NULL){
                fprintf(stderr, "ROBOT_ID must be defined\n");
                return "Error";
        }      
        char *name=(char*) malloc((strlen(msgName)+strlen(robotID)+strlen("Robot")+2)*sizeof(char));
        strcpy(name,"Robot");
        strcat(name,robotID);
        strcat(name,"/");
        strcat(name,msgName);

        //printf("\n\nCreated new message name string.\n\n");
        // define message name in ipc //
        if  (IPC_defineMsg(name,IPC_VARIABLE_LENGTH,format) != IPC_OK)
                fprintf(stderr,"Could not define ipc message %s with format %s.\n",name,format);
        return name;
}

int initializeIPCMsgs() {
        
        //gpsMsgName = defineMsg("vscGPS","{double,double}");
        //heartbeatMsgName = defineMsg("vscHeartbeat","{double,double}");
        //feedbackMsgName = defineMsg("vscControllerFeedback","{double,double}");
        joystickMsgName = defineMsg("vscJoystick",EStopController_IPC_FORMAT);
        //printf("Message names: %s, %s, %s, %s\n",gpsMsgName, heartbeatMsgName, feedbackMsgName,joystickMsgName);
        return 0;
}

int initializeIPCSubscribe() {
        if (IPC_subscribeData(joystickMsgName,JoystickReceiveHandler,NULL)!=IPC_OK) {
                fprintf(stderr,"Could not subscribe to message %s.\n",joystickMsgName);
                exit(1);
        }
        printf("Subscribe to message %s.\n",joystickMsgName);
        return 0;
}

int ipcConnect(char* addr) {
        if (connectedIPC) {
                printf("Already connected to IPC.\n");
                return 0;
        }
        char * robotID=getenv("ROBOT_ID");
        if(robotID==NULL) {
                fprintf(stderr,"ROBOT_ID not defined\n");
                return -1;
        }

        int rID=strtol(robotID,NULL,10);

        if ((rID==0) && strncmp(robotID,"0",1) != 0) {
                fprintf(stderr,"Invalid ROBOT_ID %d\n",rID);
                return -1;
        }

        IPC_setVerbosity(IPC_Print_Errors);

        if (IPC_connectModule("EStopControllerGateway",addr) != IPC_OK) {
                fprintf(stderr,"Could not connect to IPC central.\n");
                return -1;
        }

        connectedIPC=true;
        return 0;
}

int initializeIPC(char * addr) {
        printf("Connecting to IPC...\n");
        connectedIPC=ipcConnect(addr);
        if (connectedIPC) {
                printf("Initializing IPC messages...\n");
                if (initializeIPCMsgs()) {
                        fprintf(stderr,"Could not initialize IPC messages.\n");
                        return -1;
                }

                printf("Initializing IPC subscriptions...\n");
                if (initializeIPCSubscribe()) {
                        fprintf(stderr,"Could not subscribe to IPC.\n");
                        return -1;
                }
        }
        else {
                fprintf(stderr,"Could not connect to IPC at %s.\n",addr);
                vsc_cleanup(vscInterface);
                exit(EXIT_FAILURE);
                return connectedIPC;
        }
        return connectedIPC;
}

int updateSubscriptions() {}

//*****************
// message handlers
//*****************
void handleHeartbeatMsg(VscMsgType *recvMsg) {
        //TODO: parse heartbeat message and publish to IPC
}

void handleGpsMsg(VscMsgType *recvMsg) {
        //TODO: parse GPS message and publish to IPC
/*        GpsMsgType *msgPtr = (GpsMsgType*) recvMsg->msg.data;
        char message[100];

        strncpy(message, (char*)msgPtr->data, recvMsg->msg.length-1);
        message[recvMsg->msg.length-1]='\0';
        printf("Received GPS Message (0x%x): %s\n",msgPtr->source,message);
*/
}

void handleFeedbackMsg(VscMsgType *recvMsg) {
        //TODO: parse user feedback message and publish to IPC
}

void handleJoystickMsg(VscMsgType *recvMsg) {
        //TODO: parse joystick message and publish to IPC
        JoystickMsgType *joyMsg = (JoystickMsgType*) recvMsg->msg.data;
        EStopController esc;
                
        esc.leftX = GET_JOY(joyMsg->leftX);
        esc.leftY = GET_JOY(joyMsg->leftY);
        esc.leftZ = GET_JOY(joyMsg->leftZ);
        esc.rightX = GET_JOY(joyMsg->rightX);
        esc.rightY = GET_JOY(joyMsg->rightY);
        esc.rightZ = GET_JOY(joyMsg->rightZ);

        esc.bD=GET_BUT(joyMsg->leftSwitch.home);
        esc.bR=GET_BUT(joyMsg->leftSwitch.first);
        esc.bU=GET_BUT(joyMsg->leftSwitch.second);
        esc.bL=GET_BUT(joyMsg->leftSwitch.third);

        esc.b1=GET_BUT(joyMsg->rightSwitch.home);
        esc.b2=GET_BUT(joyMsg->rightSwitch.first);
        esc.b3=GET_BUT(joyMsg->rightSwitch.second);
        esc.b4=GET_BUT(joyMsg->rightSwitch.third);

        if(publishMsg(joystickMsgName,&esc))
                fprintf(stderr,"Joystick Message publish failed\n");
        else
                printf("Joystick message published!\n");
        /*
        printf("%i\t%i\t%i\t|\t%i\t%i\t%i\t|\t%u %u %u %u | %u %u %u %u\n",
               esc.leftX,esc.leftY,esc.leftZ,
               esc.rightX,esc.rightY,esc.rightZ,
               esc.bD,esc.bR,esc.bU,esc.bL,
               esc.b1,esc.b2,esc.b3,esc.b4);
        */
}

//*******************
// parse VSC messages
//*******************
void readVSCMsg() {
        // receive messages //
        VscMsgType recvMsg;
        while (vsc_read_next_msg(vscInterface, &recvMsg) > 0) {
                // parse each type of message that comes through //
                switch(recvMsg.msg.msgType) {
                case MSG_VSC_HEARTBEAT:   // heartbeat message //
                        handleHeartbeatMsg(&recvMsg);
                        break;
                case MSG_VSC_NMEA_STRING: // GPS message //
                        handleGpsMsg(&recvMsg);
                        break;
                case MSG_USER_FEEDBACK:   // user feedback message //
                        handleFeedbackMsg(&recvMsg);
                        break;
                case MSG_VSC_JOYSTICK:    // joystick message //
                        handleJoystickMsg(&recvMsg);
                        break;
                default:                  // invalid message //
                        printf("Invalid Message Type (0x%02X)\n",recvMsg.msg.msgType);
                        break;
                }
        }
}

//**************
// main function
//**************
int main(int argc, char * argv[]) {
        // timing variables //
        struct timespec lastSent, timeNow, lastReceived, timeDiff;
        struct timeval timeout;

        // VSC port //
        char *address = ESTOP_CONTROLLER_DEF_NAME;

        // IPC address and connection confirmation //
        char *ipcHost = "localhost";
        int ipcconnect;

        // file descriptors and input stream for opened VSC port //
        int max_fd, vsc_fd, retval;
        fd_set input;

        // obtain user input device address and id //
        if (argc>1)
                address=argv[1];  

        // Catch CTRL-C //
        signal(SIGINT, exit_handler);


        // attempt to connect to vsc interface //
        vscInterface = vsc_initialize(address,ESTOP_CONTROLLER_BAUD_RATE);
        if (vscInterface==NULL) {
                printf("Opening VSC Interface failed.\n");
                exit(EXIT_FAILURE);
        }
        connectedSerial=true;
        printf("Opened VSC Interface.\n"); // connected to VSC

        // Initialize the input set //
        vsc_fd = vsc_get_fd(vscInterface);
        FD_ZERO(&input);
        FD_SET(vsc_fd, &input);
        max_fd = vsc_fd + 1;

        // initialize IPC //
        ipcconnect=initializeIPC(ipcHost);//address);
        if (ipcconnect==-1) {
                
                vsc_cleanup(vscInterface);
                exit(-1);
        }

        // Reset timing values to the current time //
        clock_gettime(CLOCK_REALTIME, &lastSent);
        clock_gettime(CLOCK_REALTIME, &lastReceived);

        // Send Heartbeat Message to VSC //
        vsc_send_heartbeat(vscInterface, ESTOP_STATUS_NOT_SET);

        // INFINITE LOOP //
        while(1) {
                // get current time //
                clock_gettime(CLOCK_REALTIME, & timeNow);
    
                // if 50 milliseconds have passed, send another heartbeat message //
                if (diffTime(lastSent, timeNow, &timeDiff) > 50000) {
                        lastSent = timeNow;
                        vsc_send_heartbeat(vscInterface, ESTOP_STATUS_NOT_SET);
                }
        
                // if socket received another message, parse it. //
                // otherwise, timeout for 50 milliseconds        //
                timeout.tv_sec = 0;
                timeout.tv_usec = (50000 - (diffTime(lastSent, timeNow, &timeDiff) * 0.001));
    
                FD_ZERO(&input);
                FD_SET(vsc_fd, &input);
                max_fd = vsc_fd + 1;
    
                retval = select(max_fd, &input, NULL, NULL, &timeout);

                // if socket check failed, print error message //
                if (retval < 0) {
                        fprintf(stderr, "Socket check failed.\n");
                }
                // else if no data was received, print time since last message //
                else if(retval == 0) {
                        clock_gettime(CLOCK_REALTIME, &timeNow);
                        diffTime(lastReceived, timeNow, &timeDiff);
                        if(timeDiff.tv_sec > 0) {
                                printf("No data received from VSC in %li.%09li seconds\n", timeDiff.tv_sec, timeDiff.tv_nsec);
                        }
                }
                // else if message was received, check if it's from the VSC //
                else {
                        // if it's from the VSC, parse through messages //
                        if (FD_ISSET(vsc_fd, &input)) {
                                // receive messages //
                                readVSCMsg();
                                updateSubscriptions();
                                clock_gettime(CLOCK_REALTIME, &lastReceived);
                        }
                        else
                                fprintf(stderr, "Invalid file descriptor set\n");
                } // end socket checks
        } // end infinite loop
        
        // just in case
        printf("Cleaning up VSC Interface...\n");
        vsc_cleanup(vscInterface);
        printf("Done cleaning.\n");

        return 0;
}
