function [xmin, ymin] = interpMin(y, x);
% Finds quadratic interpolation of min of y
% Bounded by limits of x

ny = length(y);

if nargin < 2,
  x = 1:ny;
end


[ymin, imin] = min(y);

if imin == 1,
  xmin = x(1);
elseif imin == ny,
  xmin = x(ny);
else
  y1 = y(imin-1)-y(imin);
  y2 = y(imin+1)-y(imin);
  
  x1 = x(imin-1)-x(imin);
  x2 = x(imin+1)-x(imin);
  
  dx = (x2^2*y1-x1^2*y2)/(x2*y1-x1*y2);
  
  xmin = x(imin) + dx;
end
