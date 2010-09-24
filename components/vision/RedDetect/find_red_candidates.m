function [red,stats] = find_red_candidates(image)
	[Y,red] = Get_YCr_only(image);
%	notwhite = sum(image,3)<765; % mask out completely white pixels 
%	Ymod = Y;
%	Ymod = Ymod(notwhite(:));
%	Ymean = mean(Ymod(:))/256*2;
	
	%Cr_threshold = max(190,max(Cr(:)) - 20);
	%imCr_filt = Cr > Cr_threshold;
	redr = round(red/10)+1;
	h = histc(redr(:),1:26);
	[v,i] = max(h);
	h(1:i) = 0; 
	h = h/sum(h);
	h = [0;h];
	h = h.^-1;
	h(isinf(h)) = 0;   	  
	redw = h(redr).*redr; 
		
	
%	size(imCr_filt)i
	redcr = bwareaopen(redw>0,round(prod(size(redr))/10000));
    	[redcr,num] = bwlabel(redcr);
	redcr = sparse(redcr); 
	map = zeros(size(redcr)); 
	stats = []; 
	for i = 1:num
		blob = sparse(redcr == i);
		[I,J,V] = find(blob); 
		m = mean(redw(blob)); 
		stats = [[i,m,min(I),max(I),min(J),max(J)];stats]; 
		map(blob) = m;
	end
	stats = [stats;[0 0 1 1 1 1]];   
	stats = [stats;[0 0 1 1 1 1]];   
	stats = [stats;[0 0 1 1 1 1]];   
	if size(stats,1) > 1
		stats = flipud(sortrows(stats,2));  
	end
%	subplot(3,1,1); 
%	imagesc(image); daspect([1 1 1])
%%	red = red([red.area] > 20);
%	for i = 1:size(stats,1)
%		linecolor = 'blue';
%		if i == 3
%			linecolor = 'red';
%		end
%		if i == 2
%			linecolor = 'yellow';
%		end
%		if i == 1
%			linecolor = 'green';
%		end
%		bb = stats(i,3:end); 
%		line([bb(3),bb(4)],[bb(1),bb(1)],'Color',linecolor,'LineWidth',2);
%		line([bb(3),bb(4)],[bb(2),bb(2)],'Color',linecolor,'LineWidth',2);
%		line([bb(3),bb(3)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
%		line([bb(4),bb(4)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
%	end
%	subplot(3,1,2);
%	bb = stats(1,3:end) + [-25,25,-25,25];  
%	bb(1) = max(bb(1),1); 
%	bb(3) = max(bb(3),1); 
%	bb(2) = min(bb(2),size(image,1)); 
%	bb(4) = min(bb(4),size(image,2)); 
%	bb = round(bb);
%	bb 
%	imagesc(image(bb(1):bb(2),bb(3):bb(4),:));
%	daspect([1 1 1]);  
%	subplot(3,1,3);
%	bb = stats(2,3:end) + [-25,25,-25,25];  
%	bb(1) = max(bb(1),0); 
%	bb(3) = max(bb(3),0); 
%	bb(2) = min(bb(2),size(image,1)); 
%	bb(4) = min(bb(4),size(image,2)); 
%	imagesc(image(bb(1):bb(2),bb(3):bb(4),:));
%	daspect([1 1 1]);  
