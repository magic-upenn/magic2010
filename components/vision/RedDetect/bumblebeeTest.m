figure('Position',[1,1,1000,500])
for i = 1:1000000
	[x,info,ex] = bumblebeeCapture(0);
	 [l,r] = bumblebeeRawToLeftRight(x);
	l = permute(l,[2,1,3]); 
	r = permute(r,[2,1,3]); 
	subplot(1,2,1); 
	imagesc(l); 
	daspect([1 1 1]); 
	subplot(1,2,2); 
	imagesc(r)
	daspect([1 1 1]); 
	pause(.1)
end

