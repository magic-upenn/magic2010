/*
   status = libdc1394(args);

   Matlab R14 Linux MEX file
   to interface to libdc1394 (RC5) library.

   Compile with:
   mex -O libdc1394.cc -I/usr/local/include -ldc1394

   Daniel D. Lee, 1/07
   <ddlee@seas.upenn.edu>
*/

#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>

#include "mex.h"

#include <dc1394/conversions.h>
#include <dc1394/control.h>
#include <dc1394/utils.h>
#include <dc1394/register.h>

typedef unsigned char uint8;
typedef unsigned short uint16;

dc1394camera_t** cameras = NULL;
dc1394camera_t *camera = NULL;
unsigned int nCameras = 0;
unsigned int iCamera = 0;

void mexExit(void) {
  for (int i = 0; i < nCameras; i++) {
    dc1394_capture_stop(cameras[i]);
    dc1394_video_set_transmission(cameras[i], DC1394_OFF);
    dc1394_free_camera(cameras[i]);
  }
}


dc1394feature_t parseFeatureName(char *buf) {
  dc1394feature_t feature;
  
  for (int i = 0; i < DC1394_FEATURE_NUM; i++) {
    if (strcasecmp(buf,dc1394_feature_desc[i]) == 0) {
      feature = (dc1394feature_t) (DC1394_FEATURE_MIN + i);
      return feature;
    }
  }

  mexErrMsgTxt("Unknown feature name");
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int BUFLEN = 256;
  char buf[BUFLEN];
  dc1394error_t err;

  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  if (mxGetString(prhs[0], buf, BUFLEN) != 0) {
    mexErrMsgTxt("Could not read string.");
  }

  if (cameras == NULL) {
    err = dc1394_find_cameras(&cameras, &nCameras);
    
    if (err != DC1394_SUCCESS) {
      mexErrMsgTxt("Error in dc1394_find_cameras");
    }

    iCamera = 0;
    camera = cameras[iCamera];
    mexAtExit(mexExit);
  }

  
  if (strcmp(buf, "capture") == 0) {
    dc1394video_frame_t *frame;

    //    unsigned char* dmaBuffer = dc1394_capture_get_buffer(camera);
    /*
    frame = dc1394_capture_dequeue_dma(camera, DC1394_VIDEO1394_WAIT);
    */
    err = dc1394_capture_dequeue(camera, DC1394_CAPTURE_POLICY_WAIT, &frame);
    unsigned char* dmaBuffer = frame->image;

    int width = frame->size[0];
    int height = frame->size[1];
    int nbytes = frame->image_bytes;
    int nbytesPixel = nbytes/(width*height);

    int dims[2];
    dims[0] = width;
    dims[1] = height;

    switch(nbytesPixel) {
    case 1:
      plhs[0] = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
      break;
    case 2:
      plhs[0] = mxCreateNumericArray(2,dims,mxUINT16_CLASS,mxREAL);
      break;
    case 4:
      plhs[0] = mxCreateNumericArray(2,dims,mxUINT32_CLASS,mxREAL);
      break;
    default:
      dims[0] = width*nbytesPixel;
      plhs[0] = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
    }
    
    uint8 *pr = (uint8 *) mxGetData(plhs[0]);
    memcpy(pr, dmaBuffer, nbytes);

    err = dc1394_capture_enqueue(camera, frame);

    if (nlhs > 1) {
      const char *fields[] = {
	"timestamp", "framesBehind", "id"
      };
      const int nfields = sizeof(fields)/sizeof(*fields);

      plhs[1] = mxCreateStructMatrix(1, 1, nfields, fields);

      mxSetField(plhs[1], 0, "timestamp",
		 mxCreateDoubleScalar((double)(frame->timestamp)/1e6));
      mxSetField(plhs[1], 0, "framesBehind",
		 mxCreateDoubleScalar(frame->frames_behind));
      mxSetField(plhs[1], 0, "id",
		 mxCreateDoubleScalar(frame->id));
    }

    return;
  }

  else if (strcmp(buf, "printCameraInfo") == 0) {
    err = dc1394_print_camera_info(camera);
  }

  else if (strcmp(buf, "printFeatureSet") == 0) {
    dc1394featureset_t features;

    if (dc1394_get_camera_feature_set(camera, &features) == DC1394_SUCCESS) {
      err = dc1394_print_feature_set(&features);
    }
  }

  else if (strcmp(buf, "setCameraIndex") == 0) {
    int i = (int) mxGetScalar(prhs[1]);
    if ((i < 0) || (i >= nCameras))
      mexErrMsgTxt("Invalid camera index");

    iCamera = i;
    camera = cameras[iCamera];
  }

  else if (strcmp(buf, "getCameraIndex") == 0) {
    plhs[0] = mxCreateDoubleScalar(iCamera);
    return;
  }

  else if (strcmp(buf, "getModel") == 0) {
    plhs[0] = mxCreateString(camera->model);
    return;
  }

  else if (strcmp(buf, "getCameraModel") == 0) {
    plhs[0] = mxCreateString(camera->model);
    return;
  }

  else if (strcmp(buf, "getCameraVendor") == 0) {
    plhs[0] = mxCreateString(camera->vendor);
    return;
  }

  else if (strcmp(buf, "cleanup") == 0) {
    err = dc1394_cleanup_iso_channels_and_bandwidth(camera);
  }

  else if (strcmp(buf, "reset") == 0) {
    err = dc1394_reset_camera(camera);
  }

  else if (strcmp(buf, "setCameraPower") == 0) {
    dc1394switch_t pwr = (dc1394switch_t) mxGetScalar(prhs[1]);
    err = dc1394_set_camera_power(camera, pwr);
  }

  else if (strcmp(buf, "videoSetIsoSpeed") == 0) {
    err = dc1394_video_set_iso_speed(camera, DC1394_ISO_SPEED_400);
  }

  else if (strcmp(buf, "videoGetFramerate") == 0) {
    dc1394framerate_t framerate;
    float value = 0;
	 
    // make the calls to set up the capture mode
    err = dc1394_video_get_framerate(camera, &framerate);
    if (err != DC1394_SUCCESS) {
      mexErrMsgTxt("Could not get video framerate");
    }
    
    err = dc1394_framerate_as_float(framerate, &value);
    if (err != DC1394_SUCCESS) {
      mexErrMsgTxt("Unknown video framerate");
    }

    plhs[0] = mxCreateDoubleScalar(value);
    return;
  }

  else if (strcmp(buf, "videoSetFramerate") == 0) {
    float rate = mxGetScalar(prhs[1]);

    for (int i = 0; i < DC1394_FRAMERATE_NUM; i++) {
      dc1394framerate_t framerate = 
	(dc1394framerate_t) (DC1394_FRAMERATE_MIN + i);
      float value;
      dc1394_framerate_as_float(framerate, &value);
      if (value == rate) {
	err = dc1394_video_set_framerate(camera, framerate);
	plhs[0] = mxCreateDoubleScalar(err);
	return;
      }
    }
    mexErrMsgTxt("Invalid framerate");

  }

  else if (strcmp(buf, "videoGetSupportedModes") == 0) {
    dc1394video_modes_t videoModes;

    err = dc1394_video_get_supported_modes(camera, &videoModes);
    for (int i = 0; i < videoModes.num; i++) {
      unsigned int width;
      unsigned int height;
      dc1394_get_image_size_from_video_mode(camera, videoModes.modes[i], &width, &height);
      
      dc1394color_coding_t color_coding;
      dc1394_get_color_coding_from_video_mode(camera, videoModes.modes[i], &color_coding);
      
      unsigned int bits;
      dc1394_get_color_coding_depth(color_coding, &bits);

      mexPrintf("Mode %d: %d x %d x %d bits\n",videoModes.modes[i],width,height,bits);
    }

    plhs[0] = mxCreateDoubleScalar((double) videoModes.modes[0]);
    return;

  }

  else if (strcmp(buf, "videoGetMode") == 0) {
    dc1394video_mode_t videoMode;

    err = dc1394_video_get_mode(camera, &videoMode);
    
    plhs[0] = mxCreateDoubleScalar((double) videoMode);
    return;

  }

  else if (strcmp(buf, "videoSetMode") == 0) {
    dc1394video_mode_t videoMode = (dc1394video_mode_t) mxGetScalar(prhs[1]);

    err = dc1394_video_set_mode(camera, videoMode);
  }

  else if (strcmp(buf, "captureSetup") == 0) {
    int nbuffer = (int) mxGetScalar(prhs[1]);

    err = dc1394_capture_setup(camera, nbuffer);
  }

  /*
  else if (strcmp(buf, "setVideoMode") == 0) {
    dc1394video_mode_t 	videoMode;
    dc1394framerate_t 	framerate;

    // assume hi res
    videoMode 	= DC1394_VIDEO_MODE_1024x768_MONO16;
    framerate	= DC1394_FRAMERATE_15;
	 
    // make the calls to set up the capture mode
    dc1394_video_set_iso_speed(camera, DC1394_ISO_SPEED_400);
    dc1394_video_set_mode(camera, videoMode);
    dc1394_video_set_framerate(camera, framerate);
    //    err = dc1394_capture_setup_dma(camera, 8, DC1394_RING_BUFFER_LAST);
    err = dc1394_capture_setup_dma(camera, 8, DC1394_RING_BUFFER_LAST);
    if (err != DC1394_SUCCESS)
      mexErrMsgTxt("Could not setup video capture");
  }
  */
  
  else if (strcmp(buf, "videoSetTransmission") == 0) {
    int value = (int) mxGetScalar(prhs[1]);
    err = dc1394_video_set_transmission(camera, (dc1394switch_t) value);
    if ( err != DC1394_SUCCESS ) {
      mexErrMsgTxt("Unable to set camera transmission");  
    }
  }
  
  else if (strcmp(buf, "videoGetTransmission") == 0) {
    dc1394switch_t status;
    err = dc1394_video_get_transmission(camera, &status);
    if ( err != DC1394_SUCCESS )
      mexErrMsgTxt("Unable to get camera transmission");

    plhs[0] = mxCreateDoubleScalar((double) status);
    return;
  }

  else if (strcmp(buf, "featureGetValue") == 0) {
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);

    unsigned int value;
    err = dc1394_feature_get_value(camera, feature, &value);
    if ( err != DC1394_SUCCESS ) {
      mexErrMsgTxt("Unable to get feature value");
    }

    plhs[0] = mxCreateDoubleScalar(value);
    return;
  }

  else if (strcmp(buf, "featureSetValue") == 0) { 
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);
    int value = (int) mxGetScalar(prhs[2]);

    err = dc1394_feature_set_value(camera, feature, value);
  }

  else if (strcmp(buf, "featureSetModeManual") == 0) { 
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);
    err = dc1394_feature_set_mode(camera, feature, DC1394_FEATURE_MODE_MANUAL);
  }

  else if (strcmp(buf, "featureSetModeAuto") == 0) { 
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);
    err = dc1394_feature_set_mode(camera, feature, DC1394_FEATURE_MODE_AUTO);
  }

  else if (strcmp(buf, "featureSetModeOnePushAuto") == 0) { 
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);
    err = dc1394_feature_set_mode(camera, feature, DC1394_FEATURE_MODE_ONE_PUSH_AUTO);
  }

  else if (strcmp(buf, "featureGetAbsoluteValue") == 0) {
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);

    float value;
    err = dc1394_feature_get_absolute_value(camera, feature, &value);
    if ( err != DC1394_SUCCESS ) {
      mexErrMsgTxt("Unable to get feature value");
    }

    plhs[0] = mxCreateDoubleScalar(value);
    return;
  }

  else if (strcmp(buf, "featureSetAbsoluteValue") == 0) { 
    if (mxGetString(prhs[1], buf, BUFLEN) != 0) {
      mexErrMsgTxt("Could not read feature string.");
    }

    dc1394feature_t feature = parseFeatureName(buf);
    float value = mxGetScalar(prhs[2]);

    err = dc1394_feature_set_absolute_value(camera, feature, value);
  }

  else if (strcmp(buf, "getCameraControlRegister") == 0) {
    uint32_t value;
    unsigned int reg = (unsigned int) mxGetScalar(prhs[1]);
    err = GetCameraControlRegister(camera, reg, &value);
    if ( err != DC1394_SUCCESS ) {
      mexErrMsgTxt("Unable to get camera control register");  
    }

    int dims[2];
    dims[0] = 1;
    dims[1] = 1;
    plhs[0] = mxCreateNumericArray(2,dims,mxUINT32_CLASS,mxREAL);

    *(uint32_t *)mxGetData(plhs[0]) = value;
    return;
  }

  else {
    mexErrMsgTxt("Unknown option");
  }

  // Return default output:
  plhs[0] = mxCreateDoubleScalar(err);

}
