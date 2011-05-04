function [ datac ] = meters2cells( datam,dim_min,res)
%UNTITLED11 Summary of this function goes here
%   datam = [num_dim x num_pts] in meters
%   dim_min = [xmin;ymin;zmin] // the minimum value for each dimensions
%   res = map resolution
%   datac = [num_dim x num_pts] in cells
datac = round(bsxfun(@minus,datam,dim_min)/res)+1;

end

% xc = round((xm - xmin) ./ res)+1;
% yc = round((ym - ymin) ./ res)+1;
% zc = round((zm - zmin) ./ res)+1;