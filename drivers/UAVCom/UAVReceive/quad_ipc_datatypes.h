#include "opencv2/opencv.hpp"

//definitions
#define QUAD_IMU_FORMAT "{double,double,double,double,double,double,double, double, double, double, double}"
#define QUAD_IMG_FORMAT "{double, int,int,int,<ubyte: 4>}"
#define APRIL_FORMAT "{ubyte, double, double, double, double, double, double, double, double, [double:9]}"
 
// struct for IMU over IPC
typedef struct QuadIMU {
    double t,roll,pitch,yaw,wroll,wpitch,wyaw,ax,ay,az,p;
} QuadIMU;

// struct for Image over IPC
typedef struct QuadImg {
    double t;
    int width;
    int height;
    int dim;
    uint8_t* image;
    //  static const uint8_t** returnImageRef() {return &image;}
} QuadImg;

//struct to hold april info that will be published 
typedef struct AprilInfo{
	uint8_t id;
	double t;
	double x;
	double y;
	double z;
	double yaw;
	double pitch;
	double roll;
	double distance;
	double rot[9];
}AprilInfo;

typedef struct QIH_CD {
    AprilInfo info;
    cv::Mat cameraMatrix;
    cv::Mat distCoeffs;
	//Focal Length components
	double fx;
	double fy;
	//Center point components - Not necessarily in center of image!!!
	double cx;
	double cy;
	int imageWidth; //Both width and height in pixels
	int imageHeight;
	double apriltagWidth; //Width of apriltag in meters
} QIH_CD;
