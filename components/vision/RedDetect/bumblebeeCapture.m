function [x,info,Exposure] = bumblebeeCapture;

global BUMBLEBEE;

if isempty(BUMBLEBEE),
  bumblebeeInit;
end

if libdc1394('videoGetTransmission') == 0,
  bumblebeeStartTransmission;
end

[Brightness,Exposure,Shutter,Gain] = bumblebeeGetFeatures;
fprintf(1,'Br %d, Ex %d, Sh %d, G %d\n',Brightness,Exposure,Shutter,Gain);

[x, info] = libdc1394('capture');

