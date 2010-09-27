function img = draw_cand_zoom(stats,rank,img)
	bb = stats(rank,2:end); 
	width = abs(bb(1)-bb(2)); 
	height = abs(bb(3)-bb(4)); 
	bb = bb + round([-width,width,-height,height] * .5);
	bb = max(bb,1);   
	bb(2) = min(bb(2),size(img,1)); 
	bb(4) = min(bb(4),size(img,2));
	width = abs(bb(1)-bb(2)); 
	height = abs(bb(3)-bb(4));
%	img = draw_box(img,bbtight,color); 	
	img = img(bb(1):bb(2),bb(3):bb(4),:);
	if(max(width,height) > 150)
		img = imresize(img,150/max(width,height));
	end
