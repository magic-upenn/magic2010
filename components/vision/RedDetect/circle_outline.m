function C = circle_outline(r,s,cxy)
	C = circle(r,s,cxy);  
  	C = bwperim(C); 
	C = sparse(C); 
