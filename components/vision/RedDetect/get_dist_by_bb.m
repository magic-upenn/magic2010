function dist = get_dist_by_bb(bb)
	height = abs(bb(2)-bb(1)); 
	width  = abs(bb(4)-bb(3));
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
		dist = mean([distw,disth]) ; 
	end
	if isnan(distw)
		dist = disth; 
	end
	if isnan(disth)
		dist = distw; 
	end
