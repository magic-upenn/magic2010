/**
 * file to run april software on image receieved from quad quadrotor
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

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

#include "AprilTags/TagDetector.h"
#include "AprilTags/Tag36h11.h"

#include <cmath>

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
  } else {
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




 /hoon(AprilTags::TagDetection& detection) const {
    cout << "  Id: " << detection.id
         << " (Hamming: " << detection.hammingDistance << ")";

    // recovering the relative pose of a tag:

    // NOTE: for this to be accurate, it is necessary to use the
    // actual camera parameters here as well as the actual tag size
    // (m_fx, m_fy, m_px, m_py, m_tagSize)

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

    cout << "  distance=" << translation.norm()
         << "m, x=" << translation(0)
         << ", y=" << translation(1)
         << ", z=" << translation(2)
         << ", yaw=" << yaw
         << ", pitch=" << pitch
         << ", roll=" << roll
         << endl;

    // Also note that for SLAM/multi-view application it is better to
    // use reprojection error of corner points, because the noise in
    // this relative pose is very non-Gaussian; see iSAM source code
    // for suitable factors.
  }

int main(int argc, char* argv[])
{
       //set up udp variables and connections
       UdpConnectReceive(UDP_HOST, UDP_PORT);

 	 std::list<UdpPacket> udp_packets;
	 uint8_t *image = NULL;
 	 int width, height, channels;
 	 struct timespec ts1, ts2;
 	 uint32_t count = 0;
 	 double dt_acc = 0;

       //set up pril tags variables
       cv::Mat image;
  	while(1)
 	 {
  	  UdpReceiveGetPackets(udp_packets);
  	  for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++)
         {
            count++;
            clock_gettime(CLOCK_MONOTONIC, &ts2);
            double dt = (ts2.tv_sec - ts1.tv_sec)*1000 + (ts2.tv_nsec - ts1.tv_nsec)/1e6;
            dt_acc += dt;
            //printf("dt: %f ms\n", dt);
            clock_gettime(CLOCK_MONOTONIC, &ts1);
            //parse imu data
            //decompress image data
            jpeg_decompress(&(it->data[12*4]), it->data.size(), &image, &width, &height, &channels);
           //printf("width: %d, height: %d\n", width, height);
    #if 1
          if(channels == 1)
             imgproc(image, width, height);
          else
            printf("Expecting monochrome image, got image with channels = %d\n", channels);
    #endif
         int N = 10;
         if(count % N == 0)
         {
            printf("dt: %f ms\n", dt_acc/N);
            count = 0;
            dt_acc = 0;
         }
       }
       usleep(1000);
    }
    //create cv::Mat from image data 
	

}
