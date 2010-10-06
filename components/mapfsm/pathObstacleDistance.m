function dObstacle = pathObstacleDistance(xp, yp, map, offsets)

if nargin < 4,
  offsets = [-0.28 0 0.28];
end

xp = xp(:);
yp = yp(:);

[xoffset, yoffset] = pathOffset(xp, yp, offsets);

% Subtract out unknown cost
cp = nearest(map, 'cost', xoffset, yoffset);
if (size(cp,2) > 1),
  % Find max cost along offsets
  cp = max(cp,[],2);
end

% Clip between 0 and 1:
cp = min(max(cp./90,0),1);

threshold = 0.9;
% Find first cumsum crossing of threshold:
ifind = find(cumsum(cp) > threshold);

if isempty(ifind),
  dObstacle = 100.0;
  return;
end

% Calculate distance along path:
dp = sqrt(diff(xp).^2 + diff(yp).^2);
sp = cumsum([0; dp]);

dObstacle = sp(ifind(1));
