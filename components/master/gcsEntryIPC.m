function gcsEntryIPC(ids)

global GCS
global ROBOTS
global RPOSE RMAP
global GTRANSFORM GPOSE GMAP

if nargin < 1,
  ids = [1:3];
end

GCS.ids = ids;

for id = ids,
  RPOSE{id}.x = 0;
  RPOSE{id}.y = 0;
  RPOSE{id}.yaw = 0;
  RPOSE{id}.heading = 0;
  RMAP{id} = map2d(800,800,.25,'vlidar','hlidar','cost');

  GTRANSFORM{id}.init = 0;
  GPOSE{id} = [];
end

GMAP = map2d(800, 800, .25, 'hlidar', 'cost');

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

  msgNameStateEvent = ['Robot',num2str(id),'/StateEvent'];
  ROBOTS(id).ipcAPI('define', msgNameStateEvent);
end
