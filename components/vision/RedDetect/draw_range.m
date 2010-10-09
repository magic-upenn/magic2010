function draw_range(scanH,scanV,img,axeh)
	mids = round(size(img)/2);
	steps = size(img)/15; 
	if isempty(scanH)
		scanH = zeros(15,1);
	end 
	if isempty(scanV)
		scanV = zeros(15,1);
	end 
	for txt = 1:15
		text(mids(2),round(steps(1)*(txt-1)),sprintf('%.1f',scanV(txt)),'Parent',axeh,'FontSize',16); 
		text(round(steps(2)*(txt-1)),mids(1),sprintf('%.1f',scanH(txt)),'Parent',axeh,'FontSize',16); 
	end	  

