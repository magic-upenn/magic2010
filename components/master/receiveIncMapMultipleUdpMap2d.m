function receiveIncMapMultipleUdp(host)
clear all;

global POSE USER_INPUT VIS ROBOTS CMAP

if nargin < 1
  host = 'localhost';
end

SetMagicPaths;
addpath ../mexutil/

%ipcInit('192.168.10.100');
ipcInit(host)
poseInit;
%initMapProps;
%cmapInit;
%omapInit;
%emapInit;

POSE.cntr =1;
USER_INPUT.freshClick =0;
%id of the robot that maps should be received from

addr = '192.168.10.19';
port = 12346;

UdpReceiveAPI('connect',addr,port);

CMAP = map2d(1000,1000,0.05,'cost');

%vis stuff
if checkVis
  %VIS.mapMsgName = 'CostMap2D_map2d';
  mapMsgFormat = VisMap2DSerializer('getFormat');

  VIS.updateRectMsgName   = 'CostMap2D_map2dUpdateRect';
  updateRectMsgFormat = VisMap2DUpdateRectSerializer('getFormat'); 

  VIS.updatePointsMsgName   = 'CostMap2D_map2dUpdatePoints';
  updatePointsMsgFormat = VisMap2DUpdatePointsSerializer('getFormat');


  %define messages for local viewing
  ipcAPI('connect');
  
  for ii=1:10
    VIS.mapMsgName{ii} = sprintf('Robot%d/CostMap2D_map2d',ii);
    ipcAPI('define',VIS.mapMsgName{ii},mapMsgFormat);
  end
  %ipcAPI('define',VIS.updateRectMsgName,updateRectMsgFormat);
  %ipcAPI('define',VIS.updatePointsMsgName,updatePointsMsgFormat);
end

nRobots = length(ROBOTS);
for ii=1:nRobots
  ROBOTS(ii).tr = eye(4);
  ipcAPI('define',sprintf('Robot%d/Pose',ii),MagicPoseSerializer('getFormat'));
end


tic;
while(1)
  packets = UdpReceiveAPI('receive');
  n = length(packets);
  if n > 0
    for ii=1:n
      fprintf(1,'got packet of size %d\n',length(packets(ii).data));
      packet = deserialize(zlibUncompress(packets(ii).data));
      if ~isfield(packet,'type'), continue, end
      if ~ischar(packet.type), continue, end
      
      switch(packet.type)
        case 'Pose'
          PoseMsgHandler(packet);
        case 'MapUpdateH'
          MapUpdateHMsgHandler(packet);
        case 'MapUpdateV'
          MapUpdateVMsgHandler(packet);
      end
    end
  end
  
  pause(0.01)
end

return;


function PoseMsgHandler(packet)
id = packet.id;
fprintf('got pose from robot %d\n',id);
ROBOTS(id).pose.data = packet;
ipcAPI('publishVC',sprintf('Robot%d/Pose',id),MagicPoseSerializer('serialize',ROBOTS(id).pose.data));


function MapUpdateHMsgHandler(packet)
global CMAP VIS

id = packet.id;
fprintf('got horizontal map update from robot %d\n',id);

asgn(CMAP,'cost',double(packet.xs),double(packet.ys),double(packet.cs));


if checkVis
  [dimx dimy]   = size(CMAP);
  map.xmin      = -25;
  map.ymin      = -25;
  map.res       = resolution(CMAP);
  map.map.sizex = dimx;
  map.map.sizey = dimy;
  map.map.data  = uint8(getdata(CMAP,'cost') + 100);
  imagesc(CMAP,'cost'); drawnow
  content = VisMap2DSerializer('serialize',map);
  ipcAPI('publishVC',VIS.mapMsgName{id},content);
end
  
  
function MapUpdateVMsgHandler(packet)
global CMAP

id = packet.id;
fprintf('got vertical map update from robot %d\n',id);

asgn(CMAP,'cost',double(packet.xs),double(packet.ys),double(packet.cs));

function [xi yi] = Pos2OmapInd(x,y)
global CMAP

xi = ceil((x - CMAP.xmin) * CMAP.invRes);
yi = ceil((y - CMAP.ymin) * CMAP.invRes);



%{
ids=[4];

masterConnectRobots(ids);

messages = {'PoseExternal', ...
            'IncMapUpdateH', ...
            'IncMapUpdateV'};
handles  = {@PoseMsgHandler, ...
            @MapUpdateMsgHandlerH, ... 
            @MapUpdateMsgHandlerV};
          
queueLengths = [5 5 5];
          
%subscribe to messages
masterSubscribeRobots(messages,handles,queueLengths);

%vis stuff
if checkVis
  VIS.mapMsgName = 'Robot1/CostMap2D_map2d';
  mapMsgFormat = VisMap2DSerializer('getFormat');

  VIS.updateRectMsgName   = 'Robot1/CostMap2D_map2dUpdateRect';
  updateRectMsgFormat = VisMap2DUpdateRectSerializer('getFormat'); 

  VIS.updatePointsMsgName   = 'Robot1/CostMap2D_map2dUpdatePoints';
  updatePointsMsgFormat = VisMap2DUpdatePointsSerializer('getFormat');


%define messages for local viewing
ipcAPI('connect');
ipcAPI('define',VIS.mapMsgName,mapMsgFormat);
ipcAPI('define',VIS.updateRectMsgName,updateRectMsgFormat);
ipcAPI('define',VIS.updatePointsMsgName,updatePointsMsgFormat);
end

nRobots = length(ROBOTS);
for ii=1:nRobots
  ROBOTS(ii).tr = eye(4);
  ipcAPI('define',sprintf('Robot%d/Pose',ii),MagicPoseSerializer('getFormat'));
end


while(1)
  masterReceiveFromRobots(); %will return without blocking
  pause(0.1);
end


%%%%%






while(1)
  ipcReceiveMessages;
  
  if (USER_INPUT.freshClick)
    fprintf(1,'got user input %f %f\n',USER_INPUT.x, USER_INPUT.y);
    USER_INPUT.freshClick = 0;
    
    traj.size = 1;
    traj.waypoints(1).y = USER_INPUT.x;    %switch the order here
    traj.waypoints(1).x = USER_INPUT.y;
    goal.x = USER_INPUT.x;
    goal.y = USER_INPUT.y;
    ipcAPIPublish(trajMsgName,serialize(traj));
    fprintf(1,'published traj\n');
  end
end

function PoseMsgHandler(data,name)
global ROBOTS MAP_FIGURE
  if isempty(data)
    return;
  end
  
  id = GetIdFromName(name);
  ROBOTS(id).pose.data = MagicPoseSerializer('deserialize',data);
  fprintf('got pose of robot %d\n',id);
  
  ipcAPI('publishVC',sprintf('Robot%d/Pose',id),MagicPoseSerializer('serialize',ROBOTS(id).pose.data));
  
  %fprintf(1,'got pose update\n');

function MapUpdateMsgHandlerV(data,name)
global CMAP MAP_FIGURE POSE VIS OMAP;

  if isempty(data)
    return
  end
  
  msgSize = length(data);
  fprintf(1,'got vertical map update of size %d from %s\n',msgSize,name);
  id = GetIdFromName(name);
  
  update = deserialize(data);
  
  xis = ceil((update.xs - CMAP.xmin) * CMAP.invRes);
  yis = ceil((update.ys - CMAP.ymin) * CMAP.invRes);

  indGood = (xis > 1) & (yis > 1) & (xis < CMAP.map.sizex) & (yis < CMAP.map.sizey);
  inds = sub2ind(size(CMAP.map.data),xis(indGood),yis(indGood));
  CMAP.map.data(inds) = update.cs(indGood);
  
  
  
  
function MapUpdateMsgHandlerH(data,name)
global CMAP POSE VIS OMAP;
  if isempty(data)
    return
  end
  
  msgSize = length(data);
  fprintf(1,'got horizontal map update of size %d from %s\n',msgSize,name);
  id = GetIdFromName(name);
  
  update = deserialize(data);
  
  if (1)
    xis = ceil((update.xs - CMAP.xmin) * CMAP.invRes);
    yis = ceil((update.ys - CMAP.ymin) * CMAP.invRes);

    indGood = (xis > 1) & (yis > 1) & (xis < CMAP.map.sizex) & (yis < CMAP.map.sizey);
    inds = sub2ind(size(CMAP.map.data),xis(indGood),yis(indGood));
    CMAP.map.data(inds) = update.cs(indGood);
    
    cs = update.cs(indGood);
    indsObsLogic = cs > 50;
    indsObs = inds(indsObsLogic);
    
    OMAP.map.data(indsObs) = cs(indsObsLogic);
  else
    %try to match against the current map
    %number of poses in each dimension to try
    nyaw= 41;
    nxs = 81;
    nys = 81;


    yawRange = floor(nyaw/2);
    xRange   = floor(nxs/2);
    yRange   = floor(nys/2);

    %resolution of the candidate poses
    dyaw = 0.5/180.0*pi;
    dx   = 0.05;
    dy   = 0.05;

    %create the candidate locations in each dimension
    aCand = (-yawRange:yawRange)*dyaw;
    xCand = (-xRange:xRange)*dx;
    yCand = (-yRange:yRange)*dy;

    tic
   
    %update the boundaries
    ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
    %get a local 3D sampling of pose likelihood
    
    xis = ceil((update.xs - CMAP.xmin) * CMAP.invRes);
    yis = ceil((update.ys - CMAP.ymin) * CMAP.invRes);

    indGood = (xis > 1) & (yis > 1) & (xis < CMAP.map.sizex) & (yis < CMAP.map.sizey);
    
    indObs = update.cs(indGood) > 50;
    xs = double(update.xs(indGood));
    ys = double(update.ys(indGood));
    
    xss = xs(indObs);
    yss = ys(indObs);
    
    hits = ScanMatch2D('match',OMAP.map.data,xss,yss, ...
                  xCand,yCand,aCand);

    toc
    %find maximum
    [hmax imax] = max(hits(:));
    [kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);
    
    xOffset = xCand(kmax)
    yOffset = yCand(mmax)
    aOffset = aCand(jmax)
    
    T = trans([xOffset yOffset 0])*rotz(aOffset);
    Y=T*[update.xs';update.ys';zeros(size(update.xs))';ones(size(update.xs))'];
    
    xs = Y(1,:);
    ys = Y(2,:);
    
    xis = ceil((xs - CMAP.xmin) * CMAP.invRes);
    yis = ceil((ys - CMAP.ymin) * CMAP.invRes);

    indGood = (xis > 1) & (yis > 1) & (xis < CMAP.map.sizex) & (yis < CMAP.map.sizey);
    inds = sub2ind(size(CMAP.map.data),xis(indGood),yis(indGood));
    CMAP.map.data(inds) = update.cs(indGood);
    OMAP.map.data(inds) = update.cs(indGood);
  end

  map.xmin      = CMAP.xmin;
  map.ymin      = CMAP.ymin;
  map.res       = CMAP.res;
  map.map.sizex = CMAP.map.sizex;
  map.map.sizey = CMAP.map.sizey;
  map.map.data  = uint8(CMAP.map.data + 100);
  
  if checkVis
    content = VisMap2DSerializer('serialize',map);
    ipcAPI('publishVC',VIS.mapMsgName,content);
  end
    
  expandSize = 50;
  xExpand = 0;
  yExpand = 0;

  [xi yi] = Pos2OmapInd(POSE.data.x + [-30  30], POSE.data.y + [-30 30]);
  if (xi(1) < 1), xExpand = -expandSize; end
  if (yi(1) < 1), yExpand = -expandSize; end
  if (xi(2) > CMAP.map.sizex), xExpand = expandSize; end
  if (yi(2) > CMAP.map.sizey), yExpand = expandSize; end

  if (xExpand ~=0 || yExpand ~=0)
    %expand the map
    omapExpand(xExpand,yExpand);
  end
  
  %fprintf(1,'got map update\n');
  
  
function [xi yi] = Pos2OmapInd(x,y)
global CMAP

xi = ceil((x - CMAP.xmin) * CMAP.invRes);
yi = ceil((y - CMAP.ymin) * CMAP.invRes);

%}
