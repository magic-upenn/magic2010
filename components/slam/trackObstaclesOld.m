%input: ranges and angles of lidar, T = transform from lidar frame to world
function obsTracks = trackObstacles(ranges,angles,T)
global TRACK POSE

persistent cntr

if isempty(cntr), cntr = 0; end

trackSkipCycles = 0;
obsTracks = [];
trackPeriod = 5;


rmin = 0.5;
rmax = 25;

%return empty track if we are skipping this cycle
if mod(cntr,trackSkipCycles) ~= 0
  return;
end

%calculate the clusters
clusterThreshold = 0.5;
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

minLen = 0.1; %meters
maxLen = 1.5;
isizeMatch = (obsLen > minLen) & (obsLen < maxLen) & (rmean > rmin) & (rmean < rmax);


%compute centers of the clusters
[xTrack, yTrack] = clusterCenter(ranges,angles,cistart,ciend);

%sensor frame
xts = xTrack(isizeMatch);
yts = yTrack(isizeMatch);
lt = obsLen(isizeMatch);
nTrack = length(xts);

if (length(xts) < 1)
  return;
end

T=eye(4);
X = [xts'; yts';zeros(1,nTrack);ones(1,nTrack)];
Y = T*X;

%global frame
xt = Y(1,:)';
yt = Y(2,:)';

if isempty(TRACK)
  TRACK.xs = repmat(xt,[1 trackPeriod]);
  TRACK.ys = repmat(yt,[1 trackPeriod]);
  TRACK.ls = repmat(lt,[1 trackPeriod]);
  TRACK.cs = ones(size(xt,1),1);
  TRACK.msgName = GetMsgName('VelTracks');
  ipcAPIDefine(TRACK.msgName);
else
  dxc = repmat(TRACK.xs(:,1),[1 length(xt)]) - repmat(xt',[size(TRACK.xs,1) 1]);
  dyc = repmat(TRACK.ys(:,1),[1 length(yt)]) - repmat(yt',[size(TRACK.ys,1) 1]);
  dist = dxc.^2+dyc.^2;
  [dmin, imin]  = min(dist,[],2);
  [dmin2,imin2] = min(dist,[],1); 

  vx = -TRACK.xs(:,1)+xt(imin);
  vy = -TRACK.ys(:,1)+yt(imin);

  goodTracks = sqrt(vx.^2 +vy.^2) < 0.20;
  xx = xt(imin);
  yy = yt(imin);
  ll = lt(imin);



  TRACK.cs(goodTracks) = TRACK.cs(goodTracks) + 1;
  itracked = TRACK.cs > 5;
  
  speedMin = 0.5;
  speedMax = 3.0;
  
  ptxs = xx(itracked);
  ptys = yy(itracked);
  if isempty(ptxs)
      return;
  end
  
  vtxs = (ptxs - TRACK.xs(itracked,trackPeriod))/(trackPeriod*0.025);
  vtys = (ptys - TRACK.ys(itracked,trackPeriod))/(trackPeriod*0.025);
  speeds = sqrt(vtxs.^2 + vtys.^2);
  ivelMatch = speeds > speedMin & speeds < speedMax;  
  
  obsTracks.xs  = ptxs(ivelMatch);
  obsTracks.ys  = ptys(ivelMatch);
  obsTracks.vxs = vtxs(ivelMatch);
  obsTracks.vys = vtys(ivelMatch);
  

  TRACK.xs = [xx(goodTracks) TRACK.xs(goodTracks,1:end-1) ];
  TRACK.ys = [yy(goodTracks) TRACK.ys(goodTracks,1:end-1) ];
  TRACK.ls = [ll(goodTracks) TRACK.ls(goodTracks,1:end-1) ];
  TRACK.cs = TRACK.cs(goodTracks);

  TRACK.xs = [TRACK.xs; repmat(xt(dmin2>0.10),[1 trackPeriod])];
  TRACK.ys = [TRACK.ys; repmat(yt(dmin2>0.10),[1 trackPeriod])];
  TRACK.ls = [TRACK.ls; repmat(lt(dmin2>0.10),[1 trackPeriod])];
  TRACK.cs = [TRACK.cs; ones(size(xt(dmin2>0.10),1),1)];
end
