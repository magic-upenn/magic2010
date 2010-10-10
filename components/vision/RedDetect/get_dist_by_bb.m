function [imgd,vsd,hsd] = get_dist_by_bb(img,bb,scanV,scanH)
	imgd = 0; vsd = 0; hsd = 0; 
	height = abs(bb(2)-bb(1)); 
	width  = abs(bb(4)-bb(3));
	mean_y = mean(bb(1:2)); 
	mean_x = mean(bb(3:4)); 
	stats = [
	   64.0000   95.0000    1.5240
	   34.0000   49.0000    3.0480
	   22.0000   33.0000    4.5720
	   18.0000   27.0000    6.0960
	   11.0000   15.0000    9.1440
	   10.0000   13.0000   10.6680
	    8.0000   10.0000   13.7160
	    7.0000    9.0000   15.2400
	];
	distw = interp1(stats(:,1),stats(:,3),width); 	
	disth = interp1(stats(:,1),stats(:,3),height);
	if ~isnan(distw) & ~isnan(disth)
		imgd = mean([distw,disth]) ; 
	end
	if isnan(distw)
		imgd = disth; 
	end
	if isnan(disth)
		imgd = distw; 
	end
	if isempty(img)
		return; 
	end
	sampH = numel(scanH); 
	sampV = numel(scanV);
	stepH = size(img,1)/sampH; 
	stepV = size(img,2)/sampV;
	pixelH = 1:stepH:size(img,1);  
	pixelV = 1:stepV:size(img,2);  
	hsd = interp1(pixelH,scanH,mean_y);
	vsd = interp1(pixelV,scanV,mean_x);
