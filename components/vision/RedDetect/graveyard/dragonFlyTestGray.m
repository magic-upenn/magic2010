figure('Position',[1,1,1000,500])
global CAMERAS
for i = 1:1000000
	if isfield(CAMERAS,'cam_0')
		[x,info,ex] = bumblebeeCapture(0);
		subplot(1,2,1); 
		imagesc(x');
		colormap(gray)
		daspect([1 1 1]); 
	end
	if isfield(CAMERAS,'cam_1')
		[x,info,ex] = bumblebeeCapture(1);
		subplot(1,2,2); 
		imagesc(x')
		colormap(gray)
		daspect([1 1 1]); 
	end
	pause(.1)
end
