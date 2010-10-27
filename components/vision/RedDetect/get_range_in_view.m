function [rangeH,rangeV,camHAngles,camVAngles] = get_range_in_view(scanH,scanV,img,front_angle,sampH,sampV)
	global GLOBALS
	fov = 67.5*pi/180;
	camHStep = fov/sampH; 
	camVStep = fov/sampV;
	if numel(scanH) ~= 1081
		rangeH = zeros(sampH,1);
	else
 		camHAngles = -fov/2:camHStep:fov/2 - front_angle - GLOBALS.tweekH;  
		rangeH = interp1(GLOBALS.scan_angles,scanH,camHAngles,'nearest');
	end 
	if numel(scanV) ~= 1081
		rangeV = zeros(sampV,1);
	else
 		camVAngles = -fov/2:camVStep:fov/2 - GLOBALS.tweekV;  
		rangeV = interp1(GLOBALS.scan_angles,scanV,camVAngles,'nearest');
	end

