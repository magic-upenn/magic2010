function y = bumblebeeInit;

global BUMBLEBEE;

if isempty(BUMBLEBEE),
  libdc1394('cleanup');
  
  libdc1394('printCameraInfo');
  BUMBLEBEE.index = libdc1394('getCameraIndex');

  libdc1394('videoSetIsoSpeed',400);

  mode = 78;
  libdc1394('videoSetMode', mode);
  BUMBLEBEE.mode = libdc1394('videoGetMode');

  framerate = 15;
  libdc1394('videoSetFramerate', framerate);
  BUMBLEBEE.framerate = libdc1394('videoGetFramerate');
  
  nbuffer = 8;
  libdc1394('captureSetup', nbuffer);

  libdc1394('featureSetModeAuto','brightness'); % manual 0-255
  libdc1394('featureSetModeAuto','shutter'); % auto 2-800
  libdc1394('featureSetModeManual','exposure'); % auto 2-800
  libdc1394('featureSetValue','exposure', 500); % auto 1-1023
  libdc1394('featureSetModeAuto','gain'); % auto 325-1023
end
