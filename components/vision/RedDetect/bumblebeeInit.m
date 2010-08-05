function y = bumblebeeInit(cam_index)

%Set up global camera variables
global CAMERAS;

cam_name = sprintf('cam_%d',cam_index); 
CAMERA.index = cam_index;
CAMERA.setup = 0; 
cam('setcam',cam_index);
 
  libdc1394(cam('cleanup'));
  libdc1394(cam('printCameraInfo'));
  CAMERA.index = libdc1394(cam('getCameraIndex'));

  libdc1394(cam('videoSetIsoSpeed'),400);
  CAMERA.model = libdc1394(cam('getModel')); 

  mode = 78;
  CAMERA.bayer = 'bggr'
  if strfind(CAMERA.model,'Bumblebee2')
      mode = 91; %Format 7 Mode 3 for bumblebee2
      CAMERA.bayer = 'grbg'
  else if strfind(CAMERA.model,'Dragonfly')
      mode = 69;
      CAMERA.bayer = 'bggr'
      end
  end 
  libdc1394(cam('videoSetMode'),mode);
  
  CAMERA.mode = libdc1394(cam('videoGetMode'));

  framerate = 7.5; % switch to 7.5 if frames not ready in time
  libdc1394(cam('videoSetFramerate'), framerate);
  CAMERA.framerate = libdc1394(cam('videoGetFramerate'));

%  nbuffer = 6;
%  libdc1394(cam('captureSetup'), nbuffer);
%  libdc1394('featureSetValue','Brightness', 0); % manual 0-255 (0)
                                                % Brightness seems to have
                                                % no affect on image
  libdc1394(cam('featureSetModeAuto'),'Exposure'); % auto 1-1023
%  libdc1394('featureSetModeManual','Exposure'); % 
%  libdc1394('featureSetValue','Exposure', 150); % 
  libdc1394(cam('featureSetModeAuto'),'Shutter'); % auto 2-800 (800)
%  libdc1394('featureSetModeManual','Shutter'); % Shutter seems fairly constant
%  libdc1394('featureSetValue','Shutter', 800); % in range 200-800
  libdc1394(cam('featureSetModeAuto'),'Gain'); % auto 264-1023
%  libdc1394('featureSetModeManual','Gain'); % Gain washes out above 700
%  libdc1394('featureSetValue','Gain', 1023); % 
%e
CAMERAS.(cam_name) = CAMERA;
