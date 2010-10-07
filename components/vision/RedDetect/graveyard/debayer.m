function [rgb] = debayer(raw)
	r = raw(1:2:end,1:2:end);
	g = raw(2:2:end,1:2:end);
	b = raw(2:2:end,2:2:end);
	rgb = zeros(size(r,1),size(r,2),3,'uint8');
	rgb(:,:,1) = r; 
	rgb(:,:,2) = g; 
	rgb(:,:,3) = b; 
	

