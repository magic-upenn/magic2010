figure('Position',[1,1,1000,500])
global CAMERAS
for i = 1:1000000
	if isfield(CAMERAS,'cam_0')
		[x,info,ex] = bumblebeeCapture(0);
		l = debayer(x);
		l = permute(l,[2,1,3]); 
		subplot(1,2,1); 
		imagesc(l); 
		daspect([1 1 1]); 
	end
	if isfield(CAMERAS,'cam_1')
		[x,info,ex] = bumblebeeCapture(1);
		r = debayer(x);
		r = permute(r,[2,1,3]); 
		subplot(1,2,2); 
		imagesc(r)
		daspect([1 1 1]); 
	end
	pause(.1)
end
