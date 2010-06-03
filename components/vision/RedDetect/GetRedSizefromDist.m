function [xwidth,yheight] = GetRedSizefromDist(distance)

% distance in meters. Parameters learned from rectified 192x256 images of red bin
% width 16 inches, height 22 inches.

xwidth = 139.3*exp(-0.3936*distance) + 39.86*exp(-0.06219*distance);
yheight = 196.5*exp(-0.3555*distance) + 52.34*exp(-0.05348*distance);
% in pixels
