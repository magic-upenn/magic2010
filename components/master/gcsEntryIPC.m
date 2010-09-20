function gcsEntryIPC(ids)

global GCS
global ROBOTS
global RPOSE RMAP RPATH EXPLORE_PATH
global GTRANSFORM GPOSE GMAP GPATH
global PLANMAP PLAN_DEBUG

if nargin < 1,
  ids = [1:3];
end

GCS.ids = ids;
GCS.tSave = gettime;

for id = ids,
  RPOSE{id}.x = 0;
  RPOSE{id}.y = 0;
  RPOSE{id}.yaw = 0;
  RPOSE{id}.heading = 0;
  RMAP{id} = map2d(800,800,.20,'vlidar','hlidar','cost');

  GTRANSFORM{id}.init = 0;
  GPOSE{id} = [];

  RPATH{id} = [];
  GPATH{id} = [];
  EXPLORE_PATH{id} = [];
end

%Exploration planner looks at idmax indices of GPOSE
idmax = 3;
GPOSE{idmax} = [];

GMAP = map2d(800, 800, .20, 'hlidar', 'cost');

masterConnectRobots(ids);

messages = {'PoseExternal', ...
            'IncMapUpdateH', ...
            'IncMapUpdateV', ...
            'Planner_Path'};

handles  = {@gcsRecvPoseExternal, ...
            @gcsRecvIncMapUpdateH, ...
            @gcsRecvIncMapUpdateV, ...
            @gcsRecvPlannerPathFcn};
          
queueLengths = [5 5 5 1];

if PLAN_DEBUG
  messages = [messages, 'Planner_Map'];
  handles
  handles{end+1} = @gcsRecvPlannerMapFcn;
  queueLengths = [queueLengths, 1];

  PLANMAP.map = zeros(800,800);
  PLANMAP.res = 0.1;
  PLANMAP.minX = -40;
  PLANMAP.minY = -40;
  PLANMAP.new = 0;
end

%subscribe to messages
masterSubscribeRobots(messages, handles, queueLengths);

for id = ids,
  % Define IPC messages:
  msgNamePath = ['Robot',num2str(id),'/Path'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNamePath = ['Robot',num2str(id),'/Goal_Point'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNamePath = ['Robot',num2str(id),'/Explore_Path'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNameStateEvent = ['Robot',num2str(id),'/StateEvent'];
  ROBOTS(id).ipcAPI('define', msgNameStateEvent);

  msgNameOoiDynamic = ['Robot',num2str(id),'/OoiDynamic'];
  ROBOTS(id).ipcAPI('define', msgNameOoiDynamic);
  
  %msgNamePath = ['Robot',num2str(id),'/Waypoints'];
  %ROBOTS(id).ipcAPI('define', msgNamePath, MagicGP_TRAJECTORYSerializer('getFormat'));
end
