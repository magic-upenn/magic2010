function [i, j] = xysubs(h, x, y);
% [i, j] = xysubs(h, x, y)
% Convert (x,y) coordinates to (i,j) subscripts

%i = (x-h.x0)./h.resolution + .5*(h.nx+1);
%j = (y-h.y0)./h.resolution + .5*(h.ny+1);

i = (x-h.x0)./h.resolution + .5*(h.nx);
j = (y-h.y0)./h.resolution + .5*(h.ny);