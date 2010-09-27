function draw_cand_on_axes(axeh,stats,rank,img)
	axes(axeh);
	smallest = min(size(img)); 
	bb = stats(1,2:end) + round([-1,1,-1,1] * smallest * .1);
	bb = max(bb,1);   
	bb(2) = min(bb(2),size(img,1)); 
	bb(4) = min(bb(4),size(img,2));
	imagesc(img(bb(1):bb(2),bb(3):bb(4),:));
	daspect([1 1 1]);  
