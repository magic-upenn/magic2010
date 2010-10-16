function im = show_bounding_boxes(regions,img)
	regs_im = zeros(size(img)); 
	regs_imv = zeros(size(img)); 
	for r = 1:numel(regions)
			r1 = regions(r).boundingBox(1,1) + 1; 
			r2 = regions(r).boundingBox(2,1) + 1; 
			c1 = regions(r).boundingBox(1,2) + 1; 
			c2 = regions(r).boundingBox(2,2) + 1;
			if isfield(regions(r),'score')
				mn = regions(r).score; 
			else 
				mn = 1; 
			end
			regs_im(r1:r2,c1:c2) = regs_im(r1:r2,c1:c2) + 1;  
	%		regs_imv(r1:r2,c1:c2) = regs_imv(r1:r2,c1:c2) + mn;  
	end
	%imagesc(regs_imv./regs_im); 
%	im = (regs_imv./regs_im); 
	im = regs_im; 
