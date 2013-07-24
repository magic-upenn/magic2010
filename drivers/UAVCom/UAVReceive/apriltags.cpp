/*
 * program used to detect april tags in images received over ipc. After running 
 *april, tag detection information will published to ipc
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <cstring>
#include <vector>
#include <sys/time.h>
#include <iostream>
#include <cmath>

#include "opencv2/opencv.hpp"
#include "AprilTags/TagDetector.h"
#include "AprilTags/Tag36h11.h"

#include "imgproc.h"

#include "ipc.h"
#include "quad_ipc_datatypes.h" 

#ifndef PI
const double PI = 3.14159265358979323846;
#endif
const double TWOPI = 2.0*PI;


void print_detection(AprilTags::TagDetection detection, AprilInfo* info);
const char* window_name = "Quad-April Test";
bool go_home = false;

//////////////////////////////////////////////////////////////////
////////    functions
//////////////////////////////////////////////////////////////////

/*
 *provide current system time
 */
double tic() {
	struct timeval t;
	gettimeofday(&t, NULL);
	return ((double)t.tv_sec + ((double)t.tv_usec)/1000000.0);
}

/*
 * Normalize angle  within interval [-PI, PI]
 */
inline double standardRad(double t){
	if(t>+0.0){
		t=fmod(t+PI, TWOPI)-PI;
	} else {
		t=fmod(t-PI, -TWOPI) + PI;
	}
	return t;
}

/*
 * Function used to handle AprilInfo Messages received over ipc
 */
void AprilInfoHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	AprilInfo *info = (AprilInfo*)callData;
	printf("got april info:");
	printf("id=%d, dist=%f, x=%f, y=%f, z=%f, yaw=%f, pitch=%f, roll=%f, dt=%f rot=", info->id, info->distance, info->x, info->y, info->z, info->yaw, info->pitch, info->roll, info->t);
	//for(int i=0; i<9; i++)
	//	printf(" %f", info->rot[i]);
	printf("\n");
	IPC_freeByteArray(callData);
}

/*
 * function used to handle image info received over IPC
 */
void QuadImageHandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
        QuadImg* image=(QuadImg*)callData;
	AprilInfo *info = (AprilInfo*)clientData;

	//Variables for removing the distortion
	char* conffile = "out_qc_data.xml";
	cv::Mat cameraMatrix, distCoeffs;
	cv::Mat image_und;	
    cv::FileStorage fs(conffile, cv::FileStorage::READ);

	//set up april tags variables			
	bool m_draw = true;
	AprilTags::TagCodes m_tagCodes = AprilTags::tagCodes36h11;
	AprilTags::TagDetector* m_tagDetector = new AprilTags::TagDetector(m_tagCodes);

        if (image!=NULL) {
          if (image->image != NULL) {
	    //imgproc(image->image,image->width,image->height);
	
	    //create cv::Mat from image data
	    cv::Mat image_m(cv::Size(image->width, image->height), CV_8UC1, const_cast<uint8_t*>(image->image), image->width);

		//Undistort the image
		fs["Camera_Matrix"] >> cameraMatrix;
	    fs["Distortion_Coefficients"] >> distCoeffs;

		cv::undistort(image_m, image_und, cameraMatrix, distCoeffs);

	    //Detect Tags 
	    int frame = 0;
	    double last_t = tic();
	    vector<AprilTags::TagDetection> detections = m_tagDetector->extractTags(image_und);

	    // print out each detection
	    for (int i=0; i<detections.size(); i++) {
		    print_detection(detections[i],info);
	    }

	    // show the current image including any detections
	    if (m_draw) {
		    for (int i=0; i<detections.size(); i++) {
			    // also highlight in the image
			    detections[i].draw(image_m);
		    }
		    cv::imshow(window_name, image_und); // OpenCV call
	    }

	    //Publish AprilInfo to IPC
	    if(IPC_publishData("Quad1/AprilInfo",info) != IPC_OK)
	    {
		    printf("Error publishing\n");
		    exit(1);
	    }
        printf("Published April Info!\n");
	    //calculate fps and other timing stuff
	    if (frame % 10 == 0) {
		    double t = tic();
		    //cout << "  " << 10./(t-last_t) << " fps" << endl;
		    last_t = t;
	    }

	    // exit if any key is pressed
	    if (cv::waitKey(1) >= 0) go_home = true;

	  }

        }



        IPC_freeByteArray(callData);
		
		//For the undistortion
		fs.release();
}

/*
 *convert from Rotation wRo to Euler Angles
 */
void wRo_to_euler(const Eigen::Matrix3d& wRo, double& yaw, double& pitch, double& roll) {
	yaw = standardRad(atan2(wRo(1,0), wRo(0,0)));
    	double c = cos(yaw);
    	double s = sin(yaw);
    	pitch = standardRad(atan2(-wRo(2,0), wRo(0,0)*c + wRo(1,0)*s));
    	roll  = standardRad(atan2(wRo(0,2)*s - wRo(1,2)*c, -wRo(0,1)*s + wRo(1,1)*c));
}

/*
 * function to parse detection data, print it, and prepare it for IPC
 */
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
    double rot_m[9] = {fixed_rot(0,0), fixed_rot(0,1), fixed_rot(0,2), fixed_rot(1,0), fixed_rot(1,1), fixed_rot(1,2), fixed_rot(2,0), fixed_rot(2,1), fixed_rot(2,2)};
    double yaw, pitch, roll;
    wRo_to_euler(fixed_rot, yaw, pitch, roll);
    /*
    cout << "  distance=" << translation.norm()
         << "m, x=" << translation(0)
         << ", y=" << translation(1)
         << ", z=" << translation(2)
         << ", yaw=" << yaw
         << ", pitch=" << pitch
         << ", roll=" << roll
         << endl;
    */
    //prepare info for ipc
    info->id=(uint8_t)detection.id;
    info->t=0;
    info->x=translation(0);
    info->y=translation(1);
    info->z=translation(2);
    info->yaw=yaw;
    info->pitch=pitch;
    info->roll=roll;
    info->distance=translation.norm();
    info->rot[0]=fixed_rot(0,0);
    info->rot[1]=fixed_rot(0,1);
    info->rot[2]=fixed_rot(0,2);
    info->rot[3]=fixed_rot(1,0);
    info->rot[4]=fixed_rot(1,1);
    info->rot[5]=fixed_rot(1,2);
    info->rot[6]=fixed_rot(2,0);
    info->rot[7]=fixed_rot(2,1);
    info->rot[8]=fixed_rot(2,2);

    // Also note that for SLAM/multi-view application it is better to
    // use reprojection error of corner points, because the noise in
    // this relative pose is very non-Gaussian; see iSAM source code
    // for suitable factors.
  }


/////////////////////////////////////////////////////////////////////////////////
///////////      Main Function                                            ///////
/////////////////////////////////////////////////////////////////////////////////
int main(int argc, char** argv)
{

       cv::namedWindow( window_name, CV_WINDOW_AUTOSIZE);


	//setup the environment for ipc and Apriltags
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
	if (IPC_subscribeData("Quad1/Image",QuadImageHandler,&info) != IPC_OK) {
                printf("Error subscribing\n");
                exit(1);
    }
	/*
    if ( IPC_subscribeData("Quad1/AprilInfo",AprilInfoHandler, NULL) != IPC_OK) {
		printf("Error subscribing\n");
		exit(1);
	}
    */ 
	
	
	//continuously grab image from IPC, process, and publish data back to ipc
	while(!go_home){
		IPC_listen(0);
      	}
}
