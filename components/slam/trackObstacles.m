%input: ranges and angles of lidar, T = transform from lidar frame to world
function obsTracks = trackObstacles(ranges,angles,T)
global TRACK

persistent cntr

if isempty(cntr), cntr = 0; end

trackSkipCycles = 0;
obsTracks = [];

%return empty track if we are skipping this cycle
if mod(cntr,trackSkipCycles) ~= 0
  return;
end

%calculate the clusters
clusterThreshold = 0.1;
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
maxLen = 0.6;
isizeMatch = obsLen > minLen & obsLen < maxLen;


%compute centers of the clusters
[xTrack, yTrack] = clusterCenter(ranges,angles,cistart,ciend);

%sensor frame
xts = xTrack(isizeMatch);
yts = yTrack(isizeMatch);
lt = obsLen(isizeMatch);
nTrack = length(xts);

X = [xts'; yts';zeros(1,nTrack),ones(1,nTrack)];
Y = T*X;

%global frame
xt = Y(1,:)';
yt = Y(2,:)';

%plot(xs,ys,'.'); hold on;
%plot(xt,yt,'r*');

if isempty(TRACK)
  TRACK.xs = repmat(xt,[1 trackPeriod]);
  TRACK.ys = repmat(yt,[1 trackPeriod]);
  TRACK.ls = repmat(lt,[1 trackPeriod]);
  TRACK.cs = ones(size(xt,1),1);
else
  dxc = repmat(TRACK.xs(:,1),[1 length(xt)]) - repmat(xt',[size(TRACK.xs,1) 1]);
  dyc = repmat(TRACK.ys(:,1),[1 length(yt)]) - repmat(yt',[size(TRACK.ys,1) 1]);
  dist = dxc.^2+dyc.^2;
  [dmin, imin]  = min(dist,[],2);
  [dmin2,imin2] = min(dist,[],1); 

  vx = -TRACK.xs(:,1)+xt(imin);
  vy = -TRACK.ys(:,1)+yt(imin);


  goodTracks = sqrt(vx.^2 +vy.^2) < 0.10;
  xx = xt(imin);
  yy = yt(imin);
  ll = lt(imin);



  TRACK.cs(goodTracks) = TRACK.cs(goodTracks) + 1;


  itracked = TRACK.cs > 5;
  %quiver(xx(itracked),yy(itracked),50*vx(itracked),50*vy(itracked),0,'g');
  quiver(TRACK.xs(itracked,1),TRACK.ys(itracked,1),5*(xx(itracked) - TRACK.xs(itracked,trackPeriod)),5*(yy(itracked) - TRACK.ys(itracked,trackPeriod)),0,'g');
  axis([-3 5 -7 3]);

  TRACK.xs = [xx(goodTracks) TRACK.xs(goodTracks,1:end-1) ];
  TRACK.ys = [yy(goodTracks) TRACK.ys(goodTracks,1:end-1) ];
  TRACK.ls = [ll(goodTracks) TRACK.ls(goodTracks,1:end-1) ];
  TRACK.cs = TRACK.cs(goodTracks);

  TRACK.xs = [TRACK.xs; repmat(xt(dmin2>0.10),[1 trackPeriod])];
  TRACK.ys = [TRACK.ys; repmat(yt(dmin2>0.10),[1 trackPeriod])];
  TRACK.ls = [TRACK.ls; repmat(lt(dmin2>0.10),[1 trackPeriod])];
  TRACK.cs = [TRACK.cs; ones(size(xt(dmin2>0.10),1),1)];

  %{
  TRACK.xs = [xx(goodTracks); xt(dmin2>0.10) ];
  TRACK.ys = [yy(goodTracks); yt(dmin2>0.10) ];
  TRACK.ls = [ll(goodTracks); lt(dmin2>0.10) ];
  TRACK.cs = [TRACK.cs(goodTracks); ones(size(xt(dmin2>0.10)))];
  %}
end
%hold off;
%drawnow;