function y = bumblebeeStartTransmission(cam_index);

global CAMERAS;
cam_name = sprintf('cam_%d',cam_index); 
if ~CAMERAS.(cam_name).setup
	CAMERAS.(cam_name).setup = 1; 
	nbuffer = 6;
	libdc1394(cam('captureSetup',cam_index), nbuffer);
end

if isempty(CAMERAS) | ~isfield(CAMERAS,cam_name),
  	bumblebeeInit(cam_index);
end

y = libdc1394(cam('videoSetTransmission',cam_index), 1);
