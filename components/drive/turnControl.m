function [cSteer, costMin] = turnControl(path, pose, direction)
% cSteer = turnControl(path, pose, direction)
% Value based controller to track path trajectory in pos/neg direction
% Returns optimal turn curvature

if nargin < 3,
  direction = 1;
end

sLookAhead = 0.5; % meters
turnRadius = 0.25; % meters
aCostRadius = turnRadius;

cSteerMax = 1/turnRadius;

posX = pose.x;
posY = pose.y;
heading = pose.yaw;

% Get position sLookAhead straight ahead
xs = posX + sLookAhead*cos(heading);
ys = posY + sLookAhead*sin(heading);

% Compute closest point on path
[xpath, ypath, apath] = pathClosestPoint(path, [xs ys]);

% Optimize turn command over following curvatures:
cSteerArray = cSteerMax*[-1:.025:1]';

% Calculate resulting poses over various turn trajectories:
[dx, dy, da] = calcPose(cSteerArray, sLookAhead);

x = posX + cos(heading)*dx - sin(heading)*dy;
y = posY + sin(heading)*dx + cos(heading)*dy;
a = heading+da;

xyCost = (x-xpath).^2 + (y-ypath).^2;
aCost = (aCostRadius*sin(.5*(a-apath + (direction == -1)*pi))).^2;

cost = xyCost + aCost;

[cSteer, costMin] = interpMin(cost, cSteerArray);
costMin = sqrt(costMin);
