function [rangeH,rangeV,camHAngles,camVAngles] = get_range_in_view(scanH,scanV,img,front_angle,sampH,sampV)
	global GLOBALS DEBUG
  fov = 67.5 * pi/180; 
	fovh = fov * 4/5; 
  fovv = fov * 3/5; 
	camHStep = fovh/sampH; 
	camVStep = fovv/sampV;
  if numel(scanH) ~= 1081
		rangeH = zeros(sampH,1);
	else
 		camHAngles = [0:camHStep:fovh] - fovh/2 - front_angle - GLOBALS.tweekH;  
		rangeH = interp1(GLOBALS.scan_angles,scanH,camHAngles,'nearest');
	end 
	if numel(scanV) ~= 1081
		rangeV = zeros(sampV,1);
	else
 		camVAngles = [0:camVStep:fovv] - fovv/2 - GLOBALS.tweekV;  
		rangeV = interp1(GLOBALS.scan_angles,scanV,camVAngles,'nearest');
	end
  DEBUG.camHStep = camHStep;
  DEBUG.camVStep = camVStep;
  DEBUG.fovv = fovv; 
  DEBUG.fovh = fovh; 
  DEBUG.rangeH = rangeH;
  DEBUG.rangeV = rangeV;
  DEBUG.scanH = scanH;
  DEBUG.scanV = scanV;
  DEBUG.img = img; 
  DEBUG.front_angle = front_angle; 
  DEBUG.camVAngles = camVAngles; 
  DEBUG.camHAngles = camHAngles; 
