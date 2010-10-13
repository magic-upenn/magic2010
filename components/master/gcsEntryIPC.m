function gcsEntryIPC(ids)

global GCS INIT_LOG
global ROBOTS
global RPOSE RMAP RPATH EXPLORE_PATH
global GTRANSFORM GPOSE GMAP GPATH

if nargin < 1,
  ids = [1:3];
end

GCS.ids = ids;
GCS.tSave = gettime;

for id = ids,
  if ~INIT_LOG
    RPOSE{id}.x = 0;
    RPOSE{id}.y = 0;
    RPOSE{id}.yaw = 0;
    RPOSE{id}.heading = 0;
    RMAP{id} = map2d(2000,2000,.10,'vlidar','hlidar','cost');

    GTRANSFORM{id}.init = 0;
    GPOSE{id} = [];
  end

  RPATH{id} = [];
  GPATH{id} = [];
  EXPLORE_PATH{id} = [];
end

if ~INIT_LOG
  GMAP = map2d(2000, 2000, .10, 'hlidar', 'cost');
end

masterConnectRobots(ids);


%{
messages = {'PoseExternal', ...
            'IncMapUpdateH', ...
            'IncMapUpdateV', ...
            'Planner_Path', ...
            'FSM_Status'};

handles  = {@gcsRecvPoseExternal, ...
            @gcsRecvIncMapUpdateH, ...
            @gcsRecvIncMapUpdateV, ...
            @gcsRecvPlannerPathFcn, ...
            @gcsRecvFsmStatusFcn};
          
queueLengths = [5 5 5 1 1];
%}

messages = {'Planner_Path', ...
            'FSM_Status'};

handles  = {@gcsRecvPlannerPathFcn, ...
            @gcsRecvFsmStatusFcn};
          
queueLengths = [1 1];

addr = '192.168.10.220';
port = 12346;
UdpReceiveAPI('connect',addr,port);


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

  msgNamePath = ['Robot',num2str(id),'/Avoid_Regions'];
  ROBOTS(id).ipcAPI('define', msgNamePath);

  msgNameStateEvent = ['Robot',num2str(id),'/StateEvent'];
  ROBOTS(id).ipcAPI('define', msgNameStateEvent);

  msgNameLook = ['Robot',num2str(id),'/Look_Msg'];
  ROBOTS(id).ipcAPI('define', msgNameLook);

  %msgNameOoiDynamic = ['Robot',num2str(id),'/OoiDynamic'];
  %ROBOTS(id).ipcAPI('define', msgNameOoiDynamic);
  
  %msgNamePath = ['Robot',num2str(id),'/Waypoints'];
  %ROBOTS(id).ipcAPI('define', msgNamePath, MagicGP_TRAJECTORYSerializer('getFormat'));
end
