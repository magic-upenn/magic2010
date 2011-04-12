function [stats] = find_red_candidates(red)
	range = 0:1:255;
	ratio = 16/22;  
	h = histc(red(:),range);
	h = h/sum(h);
	weight = h.^(-1); 
	weight(isinf(weight)) = 0;
	ch = cumsum(h);  	
	thresh_min = range(min(find(ch > .84)));
	thresh_max = range(min(find(ch > .99)));
	weight(1:thresh_min-1) = 0; 
	all_regs = [];
	stats = [];
	for i = thresh_min:5:thresh_max
		redcr = red > i;
		regs = connected_regions(uint8(redcr)); 
		regs = regs([regs.area] > 50); 
		for r = 1:numel(regs) 
			r1 = regs(r).boundingBox(1,1) + 1; 
		 	r2 = regs(r).boundingBox(2,1) + 1; 
			c1 = regs(r).boundingBox(1,2) + 1; 
			c2 = regs(r).boundingBox(2,2) + 1;
			vals = red(r1:r2,c1:c2);
			regs(r).mean = weight(round(mean(vals(:))));
			regs(r).width = (c2-c1); 
			regs(r).height = (r2-r1); 
			regs(r).fill = regs(r).area/(regs(r).width * regs(r).height); 
			regs(r).score = regs(r).fill * regs(r).mean; 
		end
		if numel(regs) == 0
			continue
		end
		all_regs = [all_regs;regs]; 
	end
	if numel(all_regs) > 0
		[V,I] = sort([all_regs.score],'descend');
		all_regs = all_regs(I); 		
		all_regs = filter_intersecting_boxes(all_regs);
		[V,I] = sort([all_regs.score],'descend');
		all_regs = all_regs(I); 		
		bbs = cat(3,all_regs.boundingBox)+1;
		r1 = permute([bbs(1,1,:)],[3,1,2]);
		r2 = permute([bbs(2,1,:)],[3,1,2]);
		c1 = permute([bbs(1,2,:)],[3,1,2]);
		c2 = permute([bbs(2,2,:)],[3,1,2]);
		stats = [[all_regs.score]',r1,r2,c1,c2];
	end
	stats = [stats;[0 1 1 1 1]];   
	stats = [stats;[0 1 1 1 1]];   
	stats = [stats;[0 1 1 1 1]]; 


	
