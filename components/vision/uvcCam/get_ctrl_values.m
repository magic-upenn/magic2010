cam = @uvcCam0; 
param.brightness         		= cam('get_ctrl','brightness'); 
param.contrast           		= cam('get_ctrl','contrast'); 
param.saturation         		= cam('get_ctrl','saturation'); 
param.white              		= cam('get_ctrl','white balance temperature, auto'); 
param.gain               		= cam('get_ctrl','gain'); 
param.power              		= cam('get_ctrl','power line frequency'); 
param.sharpness          		= cam('get_ctrl','sharpness'); 
param.backlight          		= cam('get_ctrl','backlight compensation'); 
param.exposure_auto      		= cam('get_ctrl','exposure, auto'); 
param.exposure_absolute  		= cam('get_ctrl','exposure (absolute); ')
param.exposure_auto_priority		= cam('get_ctrl','exposure, auto priority'); 
param.led1_mode          		= cam('get_ctrl','led1 mode'); 
param.led1_frequency     		= cam('get_ctrl','led1 frequency'); 
param.disable_video_processing		= cam('get_ctrl','disable video processing'); 
param.raw_bits_per_pixel 		= cam('get_ctrl','raw bits per pixel'); 


