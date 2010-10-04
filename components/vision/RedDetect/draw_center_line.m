function draw_center_line(handle,img,angle,req_angle)
	hold on; 
	width = size(img,2);
	height = size(img,1);
	Y = [1,round(height*.1)]; 
	
	if req_angle ~= -1; 	
		req_center = round(angle_to_pixel(img,req_angle)); 	
		req_X = [req_center,req_center]; 
		line(req_X,Y,'Color','c','Parent',handle,'LineWidth',2,'LineStyle','-','Marker','o','MarkerFaceColor','black'); 
	end
	if isempty(angle)
		angle = 0; 
	end
	center = angle_to_pixel(img,angle); 	
	X = [center,center];
	line(X,Y,'Color','m','Parent',handle,'LineWidth',2,'LineStyle','-','Marker','o','MarkerFaceColor','black'); 
	hold off; 
	%1						width
	%_______________________________________________
	%|			|			|	
	%	        	0/2pi	
			  
