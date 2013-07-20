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

#define UDP_HOST "192.168.10.132"
#define UDP_PORT 12345

using namespace std;

#include <cstring>
#include <vector>
#include <sys/time.h>
#include <iostream>

//opencv
#include "opencv2/opencv.hpp"
//apriltags
//#include "AprilTags/TagDetector.h"
//#include "AprilTags/Tag36h11.h"

#include <cmath>

//ipc
#include "ipc.h"

#define QUAD_IMU_FORMAT "{double,double,double,double,double,double}"
#define QUAD_IMG_FORMAT "{int,int,int,int,<ubyte: 4>}"

#ifndef PI
const double PI = 3.1459265358979323846;
#endif
const double TWOPI = 2.0*PI;

typedef struct QuadIMU {
        float t,roll,pitch,yaw,wroll,wpitch,wyaw,ax,ay,az,p;
} QuadIMU;

typedef struct QuadImg {
        int width;
        int height;
  int dim;
        uint8_t* image;
} QuadImg;

// utility function to provide current system time (used below in
// determining frame rate at which images are being processed)
double tic() {
        struct timeval t;
        gettimeofday(&t, NULL);
        return ((double)t.tv_sec + ((double)t.tv_usec)/1000000.);
}

void QuadImageHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
        IPC_freeByteArray(callData);
}

int main(int argc, char* argv[]) {
//set up udp variables and connections
        UdpConnectReceive(UDP_HOST, UDP_PORT);
        printf("Connected to Quad!\n");
        std::list<UdpPacket> udp_packets;
        uint8_t *image = NULL;
        int width, height, channels;
        struct timespec ts1, ts2;
        uint32_t count = 0;
        double dt_acc = 0;

        QuadIMU imu;
        QuadImg img;
//set up IPC 
        /*
        IPC_setVerbosity(IPC_Print_Errors);
        if (IPC_connectModule("Quad1",NULL) != IPC_OK) {
                printf("Error connecting to IPC\n");
                exit(1);
        }
        */
/*
        if (IPC_defineMsg("Quad1/IMU",IPC_VARIABLE_LENGTH,QUAD_IMU_FORMAT) != IPC_OK) {
                printf("ERROR defining message\n");
                exit(1);
        }
        if (IPC_defineMsg("Quad1/Image",IPC_VARIABLE_LENGTH,QUAD_IMG_FORMAT) != IPC_OK) {
                printf("Error defining message\n");
                exit(1);
        }

        if (IPC_subscribeData("Quad1/Image",QuadImageHandler,NULL) != IPC_OK) {
                printf("Error subscribing\n");
                exit(1);
        }
*/

	//float* imuvals[12];
        while(1) {
	  //IPC_listen(0);
	  UdpReceiveGetPackets(udp_packets);
	  //if(udp_packets.end() != udp_packets.begin()) {
	  //        printf("Entered if\n");
	  for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++) { 
	    count++;
	    //parse imu data
	    //for (int i=0;i<4*11;i++) {
	    //  imuvals[i]=&(it->data[i*4]);
				//}
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
	    /*
	    printf("%f %f %f %f %f %f %f %f %f %f %f\n",
		   imu.t,
		   imu.roll,imu.pitch,imu.yaw,
		   imu.wroll,imu.wpitch,imu.wyaw,
		   imu.ax,imu.ay,imu.az,
		   imu.p);
	    */
	    //decompress image data
	    jpeg_decompress(&(it->data[12*4]),
			    it->data.size(),
			    &image,
			    &(img.width),
			    &(img.height),
			    &channels);
	    
	    img.image=(uint8_t*)malloc(img.width*img.height);
	    memcpy(img.image,image,img.width*img.height);
	    if (channels == 1)
	      imgproc((uint8_t*)img.image,img.width,img.height);
	    else
	      printf("Expecting monochrome image, got image with channels = %d\n", channels);
	    free(img.image);
	  }
        } 
}
