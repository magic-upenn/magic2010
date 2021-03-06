function gcsEntryIPC()

global GCS INIT_LOG 
global ROBOT_PATH OOI_PATH NC_PATh
global ROBOTS
global RPOSE RMAP RPATH EXPLORE_PATH
global GTRANSFORM GPOSE GMAP GPATH
global MAGIC_CONSTANTS HAVE_ROBOTS

GCS.tSave = gettime;

xCells = ceil(MAGIC_CONSTANTS.mapSizeX/MAGIC_CONSTANTS.mapRes);
yCells = ceil(MAGIC_CONSTANTS.mapSizeY/MAGIC_CONSTANTS.mapRes);
xShift = (MAGIC_CONSTANTS.mapEastMax+MAGIC_CONSTANTS.mapEastMin)/2-MAGIC_CONSTANTS.mapEastOffset;
yShift = (MAGIC_CONSTANTS.mapNorthMax+MAGIC_CONSTANTS.mapNorthMin)/2-MAGIC_CONSTANTS.mapNorthOffset;

for id = GCS.ids,
  if ~INIT_LOG
    RPOSE{id}.x = 0;
    RPOSE{id}.y = 0;
    RPOSE{id}.yaw = 0;
    RPOSE{id}.heading = 0;

    RMAP{id}.x0 = 0;
    RMAP{id}.y0 = 0;
    RMAP{id}.dx = [-50.0 50.0];
    RMAP{id}.dy = [-50.0 50.0];
    resolution = 0.10;
    nx = round((RMAP{id}.dx(end)-RMAP{id}.dx(1))/resolution);
    ny = round((RMAP{id}.dy(end)-RMAP{id}.dy(1))/resolution);
    RMAP{id}.cost = zeros(nx, ny, 'int8');

    %RMAP{id} = map2d(xCells, yCells, MAGIC_CONSTANTS.mapRes,'vlidar','hlidar','cost');
    %RMAP{id} = shift(RMAP{id},xShift,yShift);
    %RMAP{id} = map2d(600,600,.10,'vlidar','hlidar','cost');

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
  ROBOT_PATH(id).x = [];
  ROBOT_PATH(id).y = [];
end
OOI_PATH = [];
NC_PATH = [];

if ~INIT_LOG
  GMAP = map2d(xCells, yCells, MAGIC_CONSTANTS.mapRes, 'hlidar', 'cost');
  GMAP = shift(GMAP,xShift,yShift);
end

if HAVE_ROBOTS
  masterConnectRobots(GCS.ids);
end

messages = {'Planner_Path', ...
            'FSM_Status'};

handles  = {@gcsRecvPlannerPathFcn, ...
            @gcsRecvFsmStatusFcn};
          
queueLengths = [1 1];

%subscribe to messages
if HAVE_ROBOTS
  masterSubscribeRobots(messages, handles, queueLengths);

  for id = GCS.ids,
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
