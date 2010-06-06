function [x, y] = subsxy(h, i, j);
% [x, y] = subsxy(h, i, j)
% Convert (i,j) subscripts to (x,y) coordinates

x = h.x0 + h.resolution*(i-.5*(h.nx+1));
y = h.y0 + h.resolution*(j-.5*(h.ny+1));
