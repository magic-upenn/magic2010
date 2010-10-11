function [theta,phi] = front_pixel_to_angle(img,x,y)
	height_f = size(img,1); 
	width_f = size(img,2); 
	theta = -(x - width_f/2)/width_f * 67.5 * pi / 180; 
	phi =   -(y - height_f/2)/height_f * 50.5 * pi / 180; 
