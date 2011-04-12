function [y,i,j] = max2(x);
% [y,i,j] = max2(x)
% y is the maximum value of matrix x,
% i,j are the indices.

[m,n] = size(x);
[y,i1] = max(x(:));

j = ceil(i1/m);
i = i1-(j-1)*m;
