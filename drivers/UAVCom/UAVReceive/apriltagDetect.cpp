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

#define UDP_HOST "192.168.10.110"
#define UDP_PORT 12345

using namespace std;

#include <cstring>
#include <vector>
#include <sys/time.h>
#include <iostream>

//opencv
#include "opencv2/opencv.hpp"
//apriltags
#include "AprilTags/TagDetector.h"
#include "AprilTags/Tag36h11.h"

#include <cmath>

//ipc
#include "ipc.h"
#define APRIL_FORMAT "{ubyte, double, double, double, double ,double, double, double, double}"

typedef struct AprilInfo {
	uint8_t id;
	double dt;
	double x;
	double y;
	double z;
	double yaw;
	double pitch;
	double roll;	
	double distance;
} AprilInfo;

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


/**
 * Normalize angle to be within the interval [-pi,pi].
 */
inline double standardRad(double t) {
        if (t >= 0.) {
                t = fmod(t+PI, TWOPI) - PI;
        }
        else {
                t = fmod(t-PI, -TWOPI) + PI;
        }
        return t;
}

void wRo_to_euler(const Eigen::Matrix3d& wRo, double& yaw, double& pitch, double& roll) {
        yaw = standardRad(atan2(wRo(1,0), wRo(0,0)));
        double c = cos(yaw);
        double s = sin(yaw);
        pitch = standardRad(atan2(-wRo(2,0), wRo(0,0)*c + wRo(1,0)*s));
        roll  = standardRad(atan2(wRo(0,2)*s - wRo(1,2)*c, -wRo(0,1)*s + wRo(1,1)*c));
}

void print_detection(AprilTags::TagDetection detection, AprilInfo* info){
//	cout << "  Id: " << detection.id
//       << " (Hamming: " << detection.hammingDistance << ")";

// recovering the relative pose of a tag:

// NOTE: for this to be accurate, it is necessary to use the
// actual camera parameters here as well as the actual tag size
// (m_fx, m_fy, m_px, m_py, m_tagSize)

//some variables
        int m_width = 640;
        int m_height = 480;
        double m_tagSize(0.166);
        double m_fx = 600;
        double m_fy = 600;
        double m_px = m_width/2;
        double m_py = m_height/2;

        Eigen::Vector3d translation;
        Eigen::Matrix3d rotation;
        detection.getRelativeTranslationRotation(m_tagSize, m_fx, m_fy, m_px, m_py,
                                                 translation, rotation);
        Eigen::Matrix3d F;
        F <<
                1, 0,  0,
                0,  -1,  0,
                0,  0,  1;
        Eigen::Matrix3d fixed_rot = F*rotation;
        double yaw, pitch, roll;
        wRo_to_euler(fixed_rot, yaw, pitch, roll);

//prepare info for ipc
        info->id=(uint8_t)detection.id;
        info->dt=0;
        info->x=translation(0);
        info->y=translation(1);
        info->z=translation(2);
        info->yaw=yaw;
        info->pitch=pitch;
        info->roll=roll;
        info->distance=translation.norm();

//publish to IPC
        if(IPC_publishData("Quad1/AprilInfo",&info) != IPC_OK)
                {
                        printf("Error publishing\n");
                        exit(1);
                }
// Also note that for SLAM/multi-view application it is better to
// use reprojection error of corner points, because the noise in
// this relative pose is very non-Gaussian; see iSAM source code
// for suitable factors.
}

void AprilInfoHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
        AprilInfo *info = (AprilInfo*)callData;
        printf("got april info:");
        printf("id=%d, dist=%f, x=%f, y=%f, z=%f, yaw=%f, pitch=%f, roll=%f, dt=%f\n",
               info->id,
               info->distance,
               info->x, info->y, info->z,
               info->yaw, info->pitch, info->roll,
               info->dt);
        IPC_freeByteArray(callData);
}

int main(int argc, char* argv[])
{
//set up udp variables and connections
        UdpConnectReceive(UDP_HOST, UDP_PORT);
        printf("Connected to Quad!\n");
        std::list<UdpPacket> udp_packets;
        uint8_t *image = NULL;
        int width, height, channels;
        struct timespec ts1, ts2;
        uint32_t count = 0;
        double dt_acc = 0;

//set up april tags variables
        bool m_draw = true;
        AprilTags::TagCodes m_tagCodes = AprilTags::tagCodes36h11;
        AprilTags::TagDetector* m_tagDetector = new AprilTags::TagDetector(m_tagCodes);
        const char* window_name = "Quad-April Test";
        cv::namedWindow( window_name, CV_WINDOW_AUTOSIZE);

//set up IPC 
        AprilInfo info;
        IPC_setVerbosity(IPC_Print_Errors);
        if (IPC_connectModule("Quad1/AprilInfo",NULL) != IPC_OK) {
                printf("Error connecting to IPC\n");
                exit(1);
        }
        if (IPC_defineMsg("Quad1/AprilInfo",IPC_VARIABLE_LENGTH,APRIL_FORMAT) != IPC_OK) {
                printf("ERROR defining message\n");
                exit(1);
        }
        if (IPC_subscribeData("Quad1/AprilInfo",AprilInfoHandler,NULL) != IPC_OK) {
                printf("Error subscribing\n");
                exit(1);
        }


        while(1) {
                IPC_listen(0);
                UdpReceiveGetPackets(udp_packets);
                if(udp_packets.end() != udp_packets.begin()) {
                        for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++) { 
                                count++;
                                clock_gettime(CLOCK_MONOTONIC, &ts2);
                                double dt = (ts2.tv_sec - ts1.tv_sec)*1000 + (ts2.tv_nsec - ts1.tv_nsec)/1e6;
                                dt_acc += dt;
                                clock_gettime(CLOCK_MONOTONIC, &ts1);
//parse imu data
//decompress image data
                                jpeg_decompress(&(it->data[12*4]), it->data.size(), &image, &width, &height, &channels);
#if 0 
                                if(channels == 1)
                                        imgproc(image, width, height);
                                else
                                        printf("Expecting monochrome image, got image with channels = %d\n", channels);
#endif
#if 0
                                int N = 10;
                                if(count % N == 0) {
                                        printf("dt: %f ms\n", dt_acc/N);
                                        count = 0;
                                        dt_acc = 0;
                                }
#endif
//create cv::Mat from image data
                                cv::Mat image_m(cv::Size(width, height), CV_8UC1, const_cast<uint8_t*>(image), width);
//Detect Tags
                                int frame = 0;
                                double last_t = tic();
                                vector<AprilTags::TagDetection> detections = m_tagDetector->extractTags(image_m);
                                
// print out each detection
//cout << detections.size() << " tags detected:" << endl;
                                for (int i=0; i<detections.size(); i++) {
                                        print_detection(detections[i],&info);
                                }
                                
// show the current image including any detections
                                if (m_draw) {
                                        for (int i=0; i<detections.size(); i++) {
// also highlight in the image
                                                detections[i].draw(image_m);
                                        }
                                        cv::imshow(window_name, image_m); // OpenCV call
                                }
                                if (frame % 10 == 0) {
                                        double t = tic();
//cout << "  " << 10./(t-last_t) << " fps" << endl;
                                        last_t = t;
                                }
                                
// exit if any key is pressed
                                if (cv::waitKey(1) >= 0) break;
                        }
                }
        } 
}
