function po = front_pixel_to_omni(omni,front,pf)
	width_o = size(omni,2); 
	width_f = size(front,2); 
	po = (pf - width_f/2 + width_o/2);
	po = round(po); 
