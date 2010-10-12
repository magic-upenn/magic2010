function im = get_image(cam,waste)
	if ~exist('waste')
		waste = 2
	end
	im = [];
	if cam == 0
		im = get_im(waste,@uvcCam0,'/dev/cam_omni',1600,1200);
	else 
		im = get_im(waste,@uvcCam1,'/dev/cam_front',800,600);
	end
	im = yuyv2rgb(im);


function im = get_im(waste,camfn,dev,width,height)
	for imc = 1:waste 
		if camfn('is_init') == 0
			'Initializing camera'
			camfn('init',dev,width,height);
			pause(1); 
			camfn('stream_on');
			if strcmp(dev,'/dev/cam_omni')
				camfn('set_ctrl','focus (absolute)',175); 	
			end 
		end
		im = camfn('read');
		while isempty(im) 
			im = camfn('read');
		end
	end

