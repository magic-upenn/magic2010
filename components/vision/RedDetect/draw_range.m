function draw_range(scanH,scanV,img,front_angle,axeh)
	global GLOBALS
	[rangeH,rangeV] = get_range_in_view(scanH,scanV,img,front_angle,30,30); 
	mids = round(size(img)/2);
	steps = [size(img,1)/numel(rangeV),size(img,2)/numel(rangeH)]; 
	for txt = 1:numel(rangeH)
		if txt == round(numel(rangeH)/2) + 1
			continue
		end
		text(round(steps(2)*(txt-1)),mids(1),sprintf('%.1f',rangeH(txt)),'Parent',axeh,'FontSize',16,'HitTest','off'); 
	end
	for txt = 1:numel(rangeV)
		text(mids(2),round(steps(1)*(txt-1)),sprintf('%.1f',rangeV(txt)),'Parent',axeh,'FontSize',16,'HitTest','off'); 
	end	  

