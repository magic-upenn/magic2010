figure('Position',[1,1,1000,500])
global CAMERAS
for i = 1:10000000
	if isfield(CAMERAS,'cam_0')
		[c1,info,ex] = bumblebeeCapture(0);
		c1 = debayer(c1);
		c1 = imresize(c1,480/size(c1,2)); 
		c1 = permute(c1,[2,1,3]); 
	end
	if isfield(CAMERAS,'cam_1')
		[c2,info,ex] = bumblebeeCapture(1);
%		c2 = debayer(x);
		c2 = permute(c2,[2,1,3]);
	end
	if isfield(CAMERAS,'cam_2')
		[c3,info,ex] = bumblebeeCapture(2);
	%	c3 = debayer(x);
		c3 = permute(c3,[2,1,3]); 
	end
	imagesc([c2,c1(:,:,1),c3])
	daspect([1,1,1])
	set(gca,'position',[0 0 1 1],'units','normalized')

	pause(.1)
end
