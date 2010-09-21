function rgb = stat_mask(img,mask)
	rgb = []; 
	for c = 1:3
		t = img(:,:,c);
		t = t(mask);
		r = 5:10:255;  
		h = histc(t,r);
		[v,i] = max(h); 
		rgb = [rgb,r(i)];  
	end 
