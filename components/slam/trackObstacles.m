%input: ranges and angles of lidar, T = transform from lidar frame to world
function obsTracks = trackObstacles(ranges,angles,T)
global

persistent cntr

if isempty(cntr), cntr = 0; end

obsTracks = [];

rmin = 0.5;
rmax = 25;

%calculate the clusters
clusterThreshold = 0.25;
clusterNMin      = 3;   %minimum number of points
[cistart ciend] = scanCluster(ranges,clusterThreshold,clusterNMin);

if isempty(cistart)
  return;
end

%find the middle range
imean = ceil((cistart+ciend)/2);
rmean = ranges(imean);

%approximate length (width) of the obstacle
obsLen = rmean .*(ciend-cistart)*0.25/180*pi; %s=r*theta

minLen = 0.2; %meters
maxLen = 1.0;
isizeMatch = (obsLen > minLen) & (obsLen < maxLen) & (rmean > rmin) & (rmean < rmax);


%compute centers of the clusters
[xTrack, yTrack] = clusterCenter(ranges,angles,cistart,ciend);

%sensor frame
xts = xTrack(isizeMatch);
yts = yTrack(isizeMatch);

if (length(xts) < 1)
  return;
end

obsTracks.xs  = xts;
obsTracks.ys  = yts;
obsTracks.vxs = zeros(size(xts));
obsTracks.vys = zeros(size(yts));
obsTracks.t   = GetUnixTime();
