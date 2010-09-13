function C = circle(cy,cx,r,s)
	g = fspecial('gaussian',round(1.25 * [r,r]),.25 * r);
	g = g / g(r,r); 
	g = min(g,1);
	cg = [r,r] * 1.25 /2 
	g(s(1),s(2)) = 0; 
	[cx,cy]-cg
	C = circshift(g,round([cx,cy]-cg));  

%	persistent x;
%	persistent y;
%	if isempty(x) || isempty(y) || any(size(x) ~= s) || any(size(y) ~= s) 
%		[x,y] = meshgrid(1:s(2),1:s(1));
%	end
%	C = sparse(((x-cx).^2 + (y-cy).^2) < r^2); 	 
