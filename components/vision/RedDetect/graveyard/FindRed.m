function [red,Ymean] = FindRed(image)
	persistent weighting; 
	if isempty(weighting); 
		weighting = repmat([0:size(image,1)-1]'/(size(image,1)-1),1,size(image,2)); 
	end
	[Y,Cr] = Get_YCr_only(image);
	size(Y)
	size(weighting)
	subplot(1,2,2); 
	notwhite = sum(image,3)<765; % mask out completely white pixels 
	Ymod = Y.*weighting; % bottom of image weighted more than top
	Ymod = Ymod(notwhite(:));
	Ymean = mean(Ymod(:))/256*2;
	Cr_threshold = max(190,max(Cr(:)) - 20);
	imCr_filt = Cr > Cr_threshold;
	imagesc(imCr_filt)
%	size(imCr_filt)
%    	red = connected_regions(uint8(imCr_filt));
%	imagesc(imCr_filt); daspect([1 1 1])
%	red = red([red.area] > 20); 
%	for i = 1:numel(red)
%        	rb1 = red(i).boundingBox(1); 
%        	rb2 = red(i).boundingBox(2); 
%        	rb3 = red(i).boundingBox(3); 
%        	rb4 = red(i).boundingBox(4); 
%		linecolor = 'blue'
%		line([rb1	,rb1+rb3],[rb2		,rb2	],'Color',linecolor);
%		line([rb1+rb3	,rb1+rb3],[rb2		,rb2+rb4],'Color',linecolor);
%		line([rb1	,rb1	],[rb2		,rb2+rb4],'Color',linecolor);
%		line([rb1	,rb1+rb3],[rb2+rb4	,rb2+rb4],'Color',linecolor);
%	end
