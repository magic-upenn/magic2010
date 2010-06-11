function gcsEntryIPC(ids)

global GCS
global ROBOTS
global RPOSE RMAP
global GTRANSFORM GPOSE GMAP

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
end

%Exploration planner looks at idmax indices of GPOSE
idmax = 3;
GPOSE{idmax} = [];

GMAP = map2d(800, 800, .20, 'hlidar', 'cost');

masterConnectRobots(ids);

messages = {'PoseExternal', ...
            'IncMapUpdateH', ...
            'IncMapUpdateV'};

handles  = {@gcsRecvPoseExternal, ...
            @gcsRecvIncMapUpdateH, ...
            @gcsRecvIncMapUpdateV};
          
queueLengths = [5 5 5];

%subscribe to messages
masterSubscribeRobots(messages, handles, queueLengths);

for id = ids,
  % Define IPC messages:
  msgNamePath = ['Robot',num2str(id),'/Path'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNamePath = ['Robot',num2str(id),'/Goal_Point'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNameStateEvent = ['Robot',num2str(id),'/StateEvent'];
  ROBOTS(id).ipcAPI('define', msgNameStateEvent);

  msgNameOoiDynamic = ['Robot',num2str(id),'/OoiDynamic'];
  ROBOTS(id).ipcAPI('define', msgNameOoiDynamic);
  
  msgNamePath = ['Robot',num2str(id),'/Waypoints'];
  ROBOTS(id).ipcAPI('define', msgNamePath, MagicGP_TRAJECTORYSerializer('getFormat'));
end
