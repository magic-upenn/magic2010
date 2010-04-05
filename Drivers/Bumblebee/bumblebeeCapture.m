function [x,info] = bumblebeeCapture;

global BUMBLEBEE;

if isempty(BUMBLEBEE),
  bumblebeeInit;
end

if libdc1394('videoGetTransmission') == 0,
  bumblebeeStartTransmission;
end

[x, info] = libdc1394('capture');

