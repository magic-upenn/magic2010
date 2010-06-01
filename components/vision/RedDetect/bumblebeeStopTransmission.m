function y = bumblebeeStopTransmission;

global BUMBLEBEE;

if isempty(BUMBLEBEE),
  bumblebeeInit;
end

y = libdc1394('videoSetTransmission', 0);
