figure('Position',[1,1,1000,500])
global CAMERAS
b = [400;300;120]; 
for i = 1:1000000
	if isfield(CAMERAS,'cam_0')
		[x,info,ex] = bumblebeeCapture(0);
		r = cat(3,x(1:3:end,:)',x(2:3:end,:)',x(3:3:end,:)'); 
		subplot(1,2,1)
		imagesc(r);
		daspect([1 1 1]);
		%set(gca,'position',[0 0 1 1],'units','normalized')
		axis off
		b = estimate_circle_fast(sum(r,3),b)
		
%		FindRed(l);  
	end
	if isfield(CAMERAS,'cam_1')
		[x,info,ex] = bumblebeeCapture(1);
		r = x; 
		%if ~exist('DEBAYER')
			r = debayer(x);
			r = permute(r,[2,1,3]); 
	%	end
		subplot(1,2,2); 
		imagesc(r)
		daspect([1 1 1]); 
	end
	pause(.1)
end
