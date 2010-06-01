function y = bumblebeeInit;

global BUMBLEBEE;

%if isempty(BUMBLEBEE),
  libdc1394('cleanup');
  
  libdc1394('printCameraInfo');
  BUMBLEBEE.index = libdc1394('getCameraIndex');

  libdc1394('videoSetIsoSpeed',400);

  mode = 78;
  libdc1394('videoSetMode', mode);
  BUMBLEBEE.mode = libdc1394('videoGetMode');

  framerate = 7.5; % switch to 7.5 if frames not ready in time
  libdc1394('videoSetFramerate', framerate);
  BUMBLEBEE.framerate = libdc1394('videoGetFramerate');
  
  nbuffer = 1;
  libdc1394('captureSetup', nbuffer);

%  libdc1394('featureSetValue','Brightness', 0); % manual 0-255 (0)
                                                % Brightness seems to have
                                                % no affect on image
  libdc1394('featureSetModeAuto','Exposure'); % auto 1-1023
%  libdc1394('featureSetModeManual','Exposure'); % 
%  libdc1394('featureSetValue','Exposure', 150); % 
  libdc1394('featureSetModeAuto','Shutter'); % auto 2-800 (800)
%  libdc1394('featureSetModeManual','Shutter'); % Shutter seems fairly constant
%  libdc1394('featureSetValue','Shutter', 800); % in range 200-800
  libdc1394('featureSetModeAuto','Gain'); % auto 264-1023
%  libdc1394('featureSetModeManual','Gain'); % Gain washes out above 700
%  libdc1394('featureSetValue','Gain', 1023); % 
%end
