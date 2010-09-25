function im = get_image(cam)
	persistent init_0; 
	persistent init_1; 
	if isempty(init_0) 
		init_0 = 0; 
		init_1 = 0; 
	end	
	im = []; 
	if cam == 0
		if init_0 == 0
			'Initializing camera 0'
			uvcCam0('init',1600,1200);
			pause(1); 
			uvcCam0('stream_on'); 
			init_0 = 1; 
			pause(1);  	
		end
		im = uvcCam0('read');
		while isempty(im) 
			im = uvcCam0('read');
		end
		im = yuyv2rgb(im);
		im = imresize(im,2,'nearest'); 
	end
	if cam == 1
		if init_1 == 0
			'Initializing camera 1'
			uvcCam1('init',800,600);
			pause(1); 
			uvcCam1('stream_on'); 
			init_1 = 1; 
			pause(1);  	
		end
		im = uvcCam1('read'); 
		while isempty(im) 
			im = uvcCam1('read'); 
		end
		im = yuyv2rgb(im);
		im = imresize(im,2,'nearest'); 
	end
