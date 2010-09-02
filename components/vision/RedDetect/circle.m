function C = circle(cx,cy,r,s)
	persistent x;
	persistent y;
	if isempty(x) || isempty(y)
		[x,y] = meshgrid(1:s(2),1:s(1));
	end
	C = sparse(((x-cx).^2 + (y-cy).^2) < r^2); 	 
