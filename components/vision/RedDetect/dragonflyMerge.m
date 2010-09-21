figure('Position',[1,1,1000,500])
global CAMERAS
for i = 1:1000000
	if isfield(CAMERAS,'cam_0')
		[x,info,ex] = bumblebeeCapture(0);
		l = debayer(x);
		l = permute(l,[2,1,3]); 
	end
	if isfield(CAMERAS,'cam_1')
		[x,info,ex] = bumblebeeCapture(1);
		r = debayer(x);
		r = permute(r,[2,1,3]); 
	end
	imagesc([l,r])
	pause(.1)
end
