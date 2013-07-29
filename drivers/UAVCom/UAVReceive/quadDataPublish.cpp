/**
 * file to run april software on image receieved from quad quadrotor
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

//kquad communication 
#include "udp.h"
#include "jpeg_decompress.h"
#include "imgproc.h"

#define UDP_HOST "127.0.0.1"
#define UDP_PORT 12345

using namespace std;

#include <cstring>
#include <vector>
#include <sys/time.h>
#include <iostream>
#include <cmath>

//opencv
#include "opencv2/opencv.hpp"

//ipc
#include "ipc.h"
#include "quad_ipc_datatypes.h"

//definitions

#define DEBUG_FLAG 0

#ifndef PI
const double PI = 3.1459265358979323846;
#endif
const double TWOPI = 2.0*PI;


// utility function to provide current system time (used below in
// determining frame rate at which images are being processed)
double tic() {
    struct timeval t;
    gettimeofday(&t, NULL);
    return ((double)t.tv_sec + ((double)t.tv_usec)/1000000.);
}


//debugging handler for IPC publications and subscriptions
void QuadImageHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
    QuadImg* img=(QuadImg*)callData;
	if (img!=NULL) {
        if (img->image != NULL) {
            imgproc(img->image,img->width,img->height); 
        }
	}
    IPC_freeByteArray(callData);
}

//IPC functions
int publishMsg(char *msgName, void *data) {
    if (IPC_publishData(msgName,data) != IPC_OK)
        return -1;
//        printf("Published %s!\n",msgName);
    return 0;
}

char* defineMsg(char * msgName, char *format) {
    if (IPC_defineMsg(msgName,IPC_VARIABLE_LENGTH,format) != IPC_OK)
        return msgName;
    return msgName;
}

void ipcConnect() {
    IPC_setVerbosity(IPC_Print_Errors);
    if (IPC_connectModule("Quad1",NULL) != IPC_OK) {
        printf("Error connecting to IPC\n");
        exit(1);
    }
}


//main
int main(int argc, char* argv[]) {
    //set up udp variables and connections
    UdpConnectReceive(UDP_HOST, UDP_PORT);
    printf("Connected to Quad!\n");
    std::list<UdpPacket> udp_packets;
    uint8_t *image = NULL;
    int width, height, channels;
    struct timespec ts1, ts2;
    uint64_t count = 0;

    QuadIMU imu;
    QuadImg img;
    //set up IPC 
	
    // IPC connect and message definition
    ipcConnect();
    defineMsg("Quad1/IMU",QUAD_IMU_FORMAT);
    defineMsg("Quad1/Image",QUAD_IMG_FORMAT);

#if DEBUG_FLAG	
    if (IPC_subscribeData("Quad1/Image",QuadImageHandler,NULL) != IPC_OK) {
        printf("Error subscribing\n");
        exit(1);
    }
#endif
    // profiling tools
    double t1=0;
    double t2=tic();

    while(1) {
          
#if DEBUG_FLAG
        IPC_listen(0);
#endif

        UdpReceiveGetPackets(udp_packets);
        for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++) { 
            //printf("t=%f\n",tic());
            //parse imu data
            int i=0;
            imu.t=*(float*)(&(it->data[4*i++]));
            imu.roll=*(float*)(&(it->data[4*i++]));
            imu.pitch=*(float*)(&(it->data[4*i++]));
            imu.yaw=*(float*)(&(it->data[4*i++]));
            imu.wroll=*(float*)(&(it->data[4*i++]));
            imu.wpitch=*(float*)(&(it->data[4*i++]));
            imu.wyaw=*(float*)(&(it->data[4*i++]));
            imu.ax=*(float*)(&(it->data[4*i++]));
            imu.ay=*(float*)(&(it->data[4*i++]));
            imu.az=*(float*)(&(it->data[4*i++]));
            imu.p=*(float*)(&(it->data[4*i++]));
	    
            //decompress image data
            jpeg_decompress(&(it->data[12*4]),
                            it->data.size(),
                            &(image),
                            &(width),
                            &(height),
                            &channels);
            img.width=width;
			img.height=height;
			img.dim=width*height;

            img.image=(uint8_t*)malloc(img.width*img.height);
            memcpy(img.image,image,img.width*img.height);
            if (channels == 1) {
                imu.t=(float)tic();
                publishMsg("Quad1/IMU",&imu);
                img.t=tic();
                count++;
                publishMsg("Quad1/Image",&img);
                static uint32_t counter=0;
                counter++;
                
                if (count % 10 == 0 && img.image != NULL) {
                    printf("Published IMU and Image %d! ",counter);
                    t1=tic();
                    printf("fps: %f\n",10./(t1-t2));
                    t2=t1;
                }
            }
            free(img.image);
        }
    } 
}
