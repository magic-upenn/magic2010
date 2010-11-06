function [theta,phi] = front_pixel_to_angle(img,x,y)
	height_f = size(img,1); 
	width_f = size(img,2); 
  fov = 67.5 * pi/180; 
	fovh = fov * 4/5; 
  fovv = fov * 3/5; 
	theta = -(x - width_f/2)/width_f * fovh; 
	phi =   -(y - height_f/2)/height_f * fovv; 
