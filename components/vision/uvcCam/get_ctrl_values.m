function param = get_ctrl_values(camnum)
	param.cam = camnum; 
	if camnum == 0
		cam = @uvcCam0; 
	elseif camnum == 1
		cam = @uvcCam1;
	else
		param.cam = 1;
		param.brightness = 128;
		param.contrast = 32;
		param.saturation = 28;
		param.white = 1;
		param.gain = 238;
		param.power = 2;
		param.sharpness = 191;
		param.backlight = 1;
		param.exposure_auto = 3;
		param.exposure_absolute = 55;
		param.exposure_auto_priority = 1;
		param.focus = 175 ;
		param.led1_mode = 3;
		param.led1_frequency = 0;
		param.disable_video_processing = 0;
		param.raw_bits_per_pixel = 0;
		return; 	
	end
param.brightness         		= cam('get_ctrl','brightness'); 
param.contrast           		= cam('get_ctrl','contrast'); 
param.saturation         		= cam('get_ctrl','saturation'); 
param.white              		= cam('get_ctrl','white balance temperature, auto'); 
param.gain               		= cam('get_ctrl','gain'); 
param.power              		= cam('get_ctrl','power line frequency'); 
param.sharpness          		= cam('get_ctrl','sharpness'); 
param.backlight          		= cam('get_ctrl','backlight compensation'); 
param.exposure_auto      		= cam('get_ctrl','exposure, auto'); 
param.exposure_absolute  		= cam('get_ctrl','exposure (absolute)');
param.exposure_auto_priority		= cam('get_ctrl','exposure, auto priority'); 

param.focus		  		= cam('get_ctrl','focus (absolute)');
param.led1_mode          		= cam('get_ctrl','led1 mode'); 
param.led1_frequency     		= cam('get_ctrl','led1 frequency'); 
param.disable_video_processing		= cam('get_ctrl','disable video processing'); 
param.raw_bits_per_pixel 		= cam('get_ctrl','raw bits per pixel'); 
