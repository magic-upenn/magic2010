function [rgb_mean, rgb_std] = stat_mask(img,mask)
	rgb_mean = [];
	rgb_std = [];
	for c = 1:3
		t = img(:,:,c);
		t = double(t(mask));
		rgb_mean = [rgb_mean,mean(t)]; 
		rgb_std  = [rgb_std ,std(t)]; 
		%r = 5:10:255;  
		%h = histc(t,r);
		%[v,i] = max(h); 
		%rgb = [rgb,r(i)];  
	end 
