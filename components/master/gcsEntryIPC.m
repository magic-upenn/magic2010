function gcsEntryIPC(ids)

global ROBOTS
global RPOSE RMAP

if nargin < 1,
  ids = [1:3];
end

for id = ids,
  RPOSE{id}.x = 0;
  RPOSE{id}.y = 0;
  RPOSE{id}.yaw = 0;
  RPOSE{id}.heading = 0;
  RMAP{id} = map2d(1500,1500,.10,'vlidar','hlidar','cost');
end

masterConnectRobots(ids);

messages = {'PoseExternal', ...
            'IncMapUpdateH', ...
            'IncMapUpdateV'};

handles  = {@handlerPoseExternal, ...
            @handlerIncMapUpdateH, ...
            @handlerIncMapUpdateV};
          
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

