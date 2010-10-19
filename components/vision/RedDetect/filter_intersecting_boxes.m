function all_regs = filter_intersecting_boxes(all_regs)
	bbs = cat(3,all_regs.boundingBox);
	r1 = permute([bbs(1,1,:)],[3,1,2]);
	r2 = permute([bbs(2,1,:)],[3,1,2]);
	c1 = permute([bbs(1,2,:)],[3,1,2]);
	c2 = permute([bbs(2,2,:)],[3,1,2]);
	heights = [all_regs.height]; 
	widths  = [all_regs.width];
	areas = heights .* widths;  
	[Vr,Ir] = sort(r1);
	[V,Iri] = sort(Ir);
	heightsr = heights(Ir);
	all_regsr = all_regs(Ir); 
	[Bh,Ah] = meshgrid(heightsr,heightsr); 
	Y = triu(min(max(Ah-squareform(pdist(Vr)),0),Bh));
	Y(logical(eye(size(Y)))) = 0; 
	[Ba,Bb,V] = find(Y); 
	if isempty(Y)
      return
  end
  Y = Y(Iri,:); 
	Y = Y(:,Iri);
	
	[Vc,Ic] = sort(c1);
	[V,Ici] = sort(Ic);
	widthsr = widths(Ic);
	all_regsr = all_regs(Ic); 
	[Bw,Aw] = meshgrid(widthsr,widthsr); 
	X = triu(min(max(Aw-squareform(pdist(Vc)),0),Bw));
	[Ba,Bb,V] = find(X); 
	if isempty(X)
      return
  end
	X = X(Ici,:); 
	X = X(:,Ici);
	X(logical(eye(size(X)))) = 0; 

	OA = X.*Y;
	[Ba,Bb,V] = find(OA); 
	OAP = [V ./ areas(Ba)', V ./ areas(Bb)']; 
	labels = 1:numel(all_regs);
	for i = 1:numel(Ba)
		Bai = Ba(i); 
		Bbi = Bb(i);
	%	[Bai,Bbi] 
	%	imagesc(show_bounding_boxes(all_regs([Bai,Bbi]),zeros(240,320))); 
		if OAP(i,1) > .55 && OAP(i,1) > .55
			La = labels(Bai); 	
			Lb = labels(Bbi);
			labels(labels == Lb) = La;
		end
	end
	delete = [];
	add = [];  
	for i = 1:numel(labels)
		merge = find(labels == i); 
		if numel(merge) > 1
			bb = round(mean(cat(3,all_regs(merge).boundingBox),3)); 
			reg.boundingBox = bb; 
			reg.score = sum([all_regs(merge).score]);
			reg.fill = mean([all_regs(merge).fill]);
			reg.mean = mean([all_regs(merge).mean]);
			reg.height = bb(2,1) - bb(1,1); 
			reg.width = bb(2,2) - bb(1,2);
			reg.centroid = mean(bb);  
			reg.area = reg.height * reg.width;  
			delete = [delete, merge]; 
			add = [add;reg]; 
			for m = merge 
				all_regs(m).score = reg.score; 
			end
		end
	end
	for i = 1:numel(Ba)
		Bai = Ba(i); 
		Bbi = Bb(i);
		if OAP(i,1) == 1 && OAP(i,2) < .55
			if all_regs(Bbi).score > all_regs(Bai).score * 1.5 
				delete = [delete, Bai]; 
			end
		end
		if OAP(i,1) < .55 && OAP(i,2) == 1
			if all_regs(Bai).score >  all_regs(Bbi).score * 1.5
				delete = [delete, Bbi]; 
			end
		end
	end
	all_regs(delete) = []; 
	all_regs = [all_regs;add]; 	
