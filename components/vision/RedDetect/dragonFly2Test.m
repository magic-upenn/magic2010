figure('Position',[1,1,1000,700])
global CAMERAS
b = [400;300;200]; %120 
for i = 1:1000000
	if isfield(CAMERAS,'cam_0')
		[x,info,ex] = bumblebeeCapture(0);
		omni = cat(3,x(1:3:end,:)',x(2:3:end,:)',x(3:3:end,:)'); 
	%	subplot(2,1,1)
	%	imagesc(r);
	%	daspect([1 1 1]);
		%set(gca,'position',[0 0 1 1],'units','normalized')
		axis off
%		if mod(i,20) == 0
%			b = estimate_circle_fast(sum(omni,3),b)
%		end
%		FindRed(l); 
		subplot(2,1,2)
		omni_flat = linear_unroll(omni,b(1),b(2)); 
		imagesc(omni_flat); 
		daspect([1 1 1]);
		axis xy 
		subplot(2,1,1); 
		%imagesc(front)
		imagesc(omni)
		daspect([1 1 1]); 
	end
	if isfield(CAMERAS,'cam_1')
		[x,info,ex] = bumblebeeCapture(1);
		r = x; 
		r = debayer(x);
		front = permute(r,[2,1,3]); 
		subplot(2,1,1); 
		%imagesc(front)
		imagesc(omni)
		daspect([1 1 1]); 
	end
	pause(.1)
end
