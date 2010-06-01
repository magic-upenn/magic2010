function [Brightness,Exposure,Shutter,Gain] = bumblebeeGetFeatures()

Brightness = libdc1394('featureGetValue','Brightness');
Exposure = libdc1394('featureGetValue','Exposure');
Shutter = libdc1394('featureGetValue','Shutter');
Gain = libdc1394('featureGetValue','Gain');

end

