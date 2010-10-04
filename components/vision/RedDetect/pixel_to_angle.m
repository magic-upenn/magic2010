function angle = pixel_to_angle(img,pixel)
	width = size(img,2);
	height = size(img,1);
	pixel = round(width - pixel + width/2);   
	if pixel > width %Loop around
		pixel = pixel - width; 
	end
	angle = pixel/width; 
	angle = angle * 2 * pi; 
