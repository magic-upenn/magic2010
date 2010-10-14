function [red,stats] = find_red_candidates(image)
	%profile on
	global red
	stats = [0 1 1 1 1];   
	stats = [stats;[0 1 1 1 1]];   
	stats = [stats;[0 1 1 1 1]]; 
	return;   
	tic
	'cr'
	red = round(Get_Cr_only(image));
	toc
%	h = histc(red(:),0:10:225);
%	[v,i] = max(h);
%	h(1:i) = 0; 
%	h = [0;h];
%	h = h.^-1;
%	h(isinf(h)) = 0;
%	bins = [0:10:230]'; 
%	h = h / sum(h);
%	h = h .* bins; 
%	h = h / sum(h);
%	thresh = bins(min(find(h)));
%	redcr = red > thresh;
%	imagesc(redcr)
%	title('old method'); 
%	pause
	range = 0:5:255; 
	h = histc(red(:),range);
	h = h/sum(h);
	ch = cumsum(h);  	
	thresh = range(min(find(ch > .99)))
	redcr = red > thresh;
	redcr = bwareaopen(redcr,10);
	[redcr,num] = bwlabel(redcr);
	redcr = sparse(redcr);
	map = zeros(size(redcr)); 
	for i = 1:num
		blob = sparse(redcr == i);
		[I,J,V] = find(blob); 
		m = mean(red(blob)); 
		stats = [[m,min(I),max(I),min(J),max(J)];stats]; 
		map(blob) = m;
	end
	if size(stats,1) > 1
		stats = flipud(sortrows(stats,1));  
	end
