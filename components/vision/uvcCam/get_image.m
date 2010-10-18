function im = get_image(cam,waste,space)
	if nargin < 2
		waste = 2
		space = 'rgb'
	end
	im = [];
	if cam == 0
		im = get_im(waste,@uvcCam0,'/dev/cam_omni',1600,1200);
	else 
		im = get_im(waste,@uvcCam1,'/dev/cam_front',640,480);
	end
	ycbcr = yuyv2ycbcr(im);
	if strcmp(space,'rgb')
		im = ycbcr2rgb(ycbcr);
	else if strcmp(space,'yuv')
		im = ycbcr; 
	end
end


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
		tic
		while isempty(im) & toc < 1;  
			im = camfn('read');
		end
	end

