function gcsEntryIPC(ids)

global GCS INIT_LOG
global ROBOTS
global RPOSE RMAP RPATH EXPLORE_PATH
global GTRANSFORM GPOSE GMAP GPATH
global MAGIC_CONSTANTS HAVE_ROBOTS

if nargin < 1,
  ids = [1:3];
end

GCS.ids = ids;
GCS.tSave = gettime;

xCells = round(MAGIC_CONSTANTS.mapSizeX/MAGIC_CONSTANTS.mapRes);
yCells = round(MAGIC_CONSTANTS.mapSizeY/MAGIC_CONSTANTS.mapRes);

for id = ids,
  if ~INIT_LOG
    RPOSE{id}.x = 0;
    RPOSE{id}.y = 0;
    RPOSE{id}.yaw = 0;
    RPOSE{id}.heading = 0;
    RMAP{id} = map2d(xCells, yCells, MAGIC_CONSTANTS.mapRes,'vlidar','hlidar','cost');

    if HAVE_ROBOTS
      GTRANSFORM{id}.init = 0;
      GPOSE{id} = [];
    else
      GTRANSFORM{id}.init = 1;
      GTRANSFORM{id}.dx = 0;
      GTRANSFORM{id}.dy = 0;
      GTRANSFORM{id}.dyaw = 0;

      GPOSE{id}.x = 0;
      GPOSE{id}.y = 0;
      GPOSE{id}.yaw = 0;
    end
  end

  RPATH{id} = [];
  GPATH{id} = [];
  EXPLORE_PATH{id} = [];
end

if ~INIT_LOG
  GMAP = map2d(xCells, yCells, MAGIC_CONSTANTS.mapRes, 'hlidar', 'cost');
end

if HAVE_ROBOTS
  masterConnectRobots(ids);
end


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
if HAVE_ROBOTS
  masterSubscribeRobots(messages, handles, queueLengths);

  for id = ids,
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

    msgNameUseServo = ['Robot',num2str(id),'/Use_Servo'];
    ROBOTS(id).ipcAPI('define', msgNameUseServo);
  end
end
