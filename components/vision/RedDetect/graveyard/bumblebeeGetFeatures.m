function [Brightness,Exposure,Shutter,Gain] = bumblebeeGetFeatures(cam_index)
cam('set_cam',cam_index);
Brightness = libdc1394(cam('featureGetValue'),'Brightness');
Exposure   = libdc1394(cam('featureGetValue'),'Exposure');
Shutter    = libdc1394(cam('featureGetValue'),'Shutter');
Gain       = libdc1394(cam('featureGetValue'),'Gain');

end

