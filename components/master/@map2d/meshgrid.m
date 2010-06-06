function [xgrid, ygrid] = meshgrid(h)

x = h.x0 + h.dx;
y = h.y0 + h.dy;

[ygrid, xgrid] = meshgrid(y,x);
