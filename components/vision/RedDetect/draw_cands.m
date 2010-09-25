function img = draw_cands(stats,img) 
	for i = 1:min(size(stats,1),25)
		color = [0,0,255];
		if i == 3
			color = [255,0,0];
			linecolor = 'red';
		end
		if i == 2
			color = [255,255,0];
			linecolor = 'yellow';
		end
		if i == 1
			color = [0,255,0];
		end
		bb = stats(i,2:end); 
		bb = max(bb,1); 
		img = draw_box(img,bb,color);  
	end
