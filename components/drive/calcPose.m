function [x,y,a] = calcPose(cSteer, s)

% Given turn curvature cSteer and look ahead distance s,
% compute new position x,y and heading a from initial zero pose

if nargin < 2,
  s = 1.0;
end

a = s.*cSteer;
ia = (a ~= 0);

x = s*ones(size(a));
y = zeros(size(a));

x(ia) = s.*sin(a(ia))./a(ia);
y(ia) = s.*(1-cos(a(ia)))./a(ia);
