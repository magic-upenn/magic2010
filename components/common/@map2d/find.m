function [x, y] = find(h, field, threshold)

if nargin < 3,
  threshold = 1;
end

[i,j] = find(h.data.(field) >= threshold);

x = h.x0 + h.dx(i);
y = h.y0 + h.dy(j);

