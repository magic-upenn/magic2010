function draw_cand_on_axes(axeh,stats,rank,img)
	axes(axeh); 
	bb = stats(1,3:end) + [-25,25,-25,25];
	bb = max(bb,1);   
	bb(1) = max(bb(1),0); 
	bb(3) = max(bb(3),0); 
	bb(2) = min(bb(2),size(img,1)); 
	bb(4) = min(bb(4),size(img,2)); 
	imagesc(img(bb(1):bb(2),bb(3):bb(4),:));
	daspect([1 1 1]);  
