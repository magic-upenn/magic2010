function [x,info,Exposure] = bumblebeeCapture(cam_index);

global CAMERAS;

cam_name = sprintf('cam_%d',cam_index); 
cam('set_cam',cam_index); 

if isempty(CAMERAS) | ~isfield(CAMERAS,cam_name),
  bumblebeeInit(cam_index);
end

CAMERA = CAMERAS.(cam_name); 

if libdc1394(cam('videoGetTransmission')) == 0,
  bumblebeeStartTransmission(cam_index);
end

[Brightness,Exposure,Shutter,Gain] = bumblebeeGetFeatures(cam_index);
%fprintf(1,'Br %d, Ex %d, Sh %d, G %d\n',Brightness,Exposure,Shutter,Gain);

[x, info] = libdc1394(cam('capture'));

