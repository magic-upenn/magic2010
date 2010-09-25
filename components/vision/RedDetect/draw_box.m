function img = draw_box(img,bb,color)
	bb = max(bb,1);   
	bb(2) = min(bb(2),size(img,1)); 
	bb(4) = min(bb(4),size(img,2));
	for c = 1:3
		for t = -1:1
			bbt = max(bb+t,1);   
			bbt(2) = min(bbt(2),size(img,1)); 
			bbt(4) = min(bbt(4),size(img,2));
			img(bb(1):bb(2),bbt(3),c) = color(c); 
			img(bb(1):bb(2),bbt(4),c) = color(c); 
			img(bbt(1),bb(3):bb(4),c) = color(c); 
			img(bbt(2),bb(3):bb(4),c) = color(c);
		end
	end
 
