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
#include <cmath>

//opencv
#include "opencv2/opencv.hpp"

//ipc
#include "ipc.h"

//definitions
#define QUAD_IMU_FORMAT "{double,double,double,double,double,double}"
#define QUAD_IMG_FORMAT "{int,int,int,int,<ubyte: 4>}"

#ifndef PI
const double PI = 3.1459265358979323846;
#endif
const double TWOPI = 2.0*PI;


// IPC publish structures
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


//debugging handler for IPC publications and subscriptions
void QuadImageHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
  QuadImg* img=(QuadImg*)callData;
  imgproc((uint8_t*)img->image,img->width,img->height); 
  IPC_freeByteArray(callData);
}

//IPC functions
int publishMsg(char *msgName, void *data) {
  if (IPC_publishData(msgName,data) != IPC_OK)
    return -1;
  return 0;
}

char* defineMsg(char * msgName, char *format) {
  if (IPC_publishData(msgName,IPC_VARIABLE_LENGTH,data) != IPC_OK)
    return -1;
  return 0;
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
  uint32_t count = 0;
  double dt_acc = 0;

  QuadIMU imu;
  QuadImg img;
  //set up IPC 
	
  ipcConnect();
  defineMsg("Quad1/IMU",QUAD_IMU_FORMAT);
  defineMsg("Quad1/Image",QUAD_IMG_FORMAT);
	
  if (IPC_subscribeData("Quad1/Image",QuadImageHandler,NULL) != IPC_OK) {
    printf("Error subscribing\n");
    exit(1);
  }


	
  while(1) {
	  
    UdpReceiveGetPackets(udp_packets);
    for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++) { 
      count++;
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
		      &image,
		      &(img.width),
		      &(img.height),
		      &channels);
	    
      img.image=(uint8_t*)malloc(img.width*img.height);
      memcpy(img.image,image,img.width*img.height);
      /*
	if (channels == 1)
	imgproc((uint8_t*)img.image,img.width,img.height);
	else
	printf("Expecting monochrome image, got image with channels = %d\n", channels);
      */
      if (channels == 1) {
	publishMsg("Quad1/IMU",&imu);
	publishMsg("Quad1/Image",&img);
      }
      free(img.image);
    }
  } 
}
