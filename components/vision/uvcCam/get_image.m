function im = get_image(cam,waste)
	if ~exist('waste')
		waste = 2
	end
	persistent init_0; 
	persistent init_1; 
	if isempty(init_0) 
		init_0 = 0; 
		init_1 = 0; 
	end	
	im = [];
	for imc = 1:waste 
		if cam == 0
			if init_0 == 0
				'Initializing camera 0'
				uvcCam0('init','/dev/video0',1600,1200);
				pause(1); 
				uvcCam0('stream_on'); 
				init_0 = 1; 
				pause(1);  	
			end
			im = uvcCam0('read');
			while isempty(im) 
				im = uvcCam0('read');
			end
		end
		if cam == 1
			if init_1 == 0
				'Initializing camera 1'
				uvcCam1('init','/dev/video1',800,600);
				pause(1); 
				uvcCam1('stream_on'); 
				init_1 = 1; 
				pause(1);  	
			end
			im = uvcCam1('read'); 
			while isempty(im) 
				im = uvcCam1('read'); 
			end
		end
	end
	im = yuyv2rgb(im);
