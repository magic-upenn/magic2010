function regs = connected_regions_matlab(img)
	[labels,num] = bwlabel(img);
	for i = 1:num
		[R,C,V] = find(labels == i);
		regs(i).boundingBox = [[min(R),min(C)];[max(R),max(C)]] - 1; 
		regs(i).area = numel(V);
		regs(i).centroid = [mean(R),mean(C)] - 1;  
	end
	regs = regs'; 
	 
