function img = apply_mask(img,mask)
	for c = 1:3
		t = img(:,:,c); t(mask) = 0; img(:,:,c) = t;
	end 
