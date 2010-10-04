function pixel = angle_to_pixel(img,angle)
	width = size(img,2);
	height = size(img,1);
	angle = angle/(2*pi);  			
	pixel = round(width/2 - angle * width); 
	if pixel < 1	%Loop around
		pixel = pixel + width;
	end
