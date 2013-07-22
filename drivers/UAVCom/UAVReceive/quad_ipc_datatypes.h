//definitions
#define QUAD_IMU_FORMAT "{double,double,double,double,double,double}"
#define QUAD_IMG_FORMAT "{int,int,int,<ubyte: 3>}"
#define APRIL_FORMAT "{ubyte, double, double, double, double, double, double, double, double, [double:9]}"
 
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

