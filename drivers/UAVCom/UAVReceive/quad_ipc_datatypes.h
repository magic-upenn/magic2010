//definitions
#define QUAD_IMU_FORMAT "{double,double,double,double,double,double}"
#define QUAD_IMG_FORMAT "{int,int,int,int,<ubyte: 4>}"
#define APRIL_FORMAT "{ubyte, double, double, double, double, double, double, double, double}"
 
// struct for IMU over IPC
typedef struct QuadIMU {
  float t,roll,pitch,yaw,wroll,wpitch,wyaw,ax,ay,az,p;
} QuadIMU;

// struct for Image over IPC
typedef struct QuadImg {
  int width;
  int height;
  int dim;
  uint8_t* image;
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
}AprilInfo;

