function params = set_ctrl_values(camnum,params)
	if camnum == 0
		cam = @uvcCam0; 
	elseif camnum == 1
		cam = @uvcCam1;
	end
old = get_ctrl_values(camnum);
if params.exposure_absolute <= 1  
	params.exposure_absolute == 1; 
	params.exposure_auto = 3; 
else
	params.exposure_auto = 1; 
end

names.brightness         		= 'brightness'; 
names.contrast           		= 'contrast'; 
names.saturation         		= 'saturation'; 
names.white              		= 'white balance temperature, auto'; 
names.gain               		= 'gain'; 
names.power              		= 'power line frequency'; 
names.sharpness          		= 'sharpness'; 
names.backlight          		= 'backlight compensation'; 
names.exposure_auto      		= 'exposure, auto'; 
names.exposure_absolute  		= 'exposure (absolute)';
names.exposure_auto_priority		= 'exposure, auto priority'; 
names.focus		  		= 'focus (absolute)';
names.led1_mode          		= 'led1 mode'; 
names.led1_frequency     		= 'led1 frequency'; 
names.disable_video_processing		= 'disable video processing'; 
names.raw_bits_per_pixel 		= 'raw bits per pixel'; 

changed = false; 
field_names = fields(names); 
for f = 1:numel(field_names)
	field = field_names{f}; 
	if strcmp(field,'exposure_auto')
		params.(field) = min(10000,max(0,params.(field)));
	else
		params.(field) = min(255,max(0,params.(field)));
	end
	if old.(field) ~= params.(field)
		sprintf('Setting %s to %d',field,params.(field))
		cam('set_ctrl',names.(field), params.(field));
		changed = true; 
		pause(.25); 
	end
end
if changed
	params = get_ctrl_values(camnum); 
end
params.camnum = camnum; 	
