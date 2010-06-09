function [xs, ys] = pathOffset(x,y,s);

x = x(:);
y = y(:);
s = s(:).';

nx = length(x);
ns = length(s);

a = pathHeading(x,y);
a = a(:);

ux = -sin(a);
uy = cos(a);

xs = repmat(x,[1 ns]) + ux*s;
ys = repmat(y,[1 ns]) + uy*s;
