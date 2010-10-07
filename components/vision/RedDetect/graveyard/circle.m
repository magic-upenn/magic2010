function C = circle(r,s,cxy)
	if ~exist('cxy')
		cxy = round(s/2); 
	end 
	c = fspecial('disk',r) > 0; 
	c(s(1),s(2)) = 0;
	C = circshift(c,round(cxy-[r,r]));  
	if size(C,1) > s(1)
		C = C(1:s(1),:); 
	end
	if size(C,2) > s(2)
		C = C(:,1:s(2)); 
	end
%	persistent x;
%	persistent y;
%	if isempty(x) || isempty(y) || any(size(x) ~= s) || any(size(y) ~= s) 
%		[x,y] = meshgrid(1:s(2),1:s(1));
%	end
%	C = sparse(((x-cx).^2 + (y-cy).^2) < r^2); 	 
