function [ datam ] = cells2meters( datac,dim_min,res)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
datam = bsxfun(@plus,(datac-1)*res,dim_min);

end