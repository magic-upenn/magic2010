function gcsEntry(ids)

global RPOSE RMAP

if nargin < 1,
  ids = [1:3];
end

for i = ids,
  RPOSE{i}.data = [];
  %  RMAP{i} = map2d(1200,1200,.15,'vlidar','hlidar');
  RMAP{i} = map2d(1200,1200,.15,'vlidar','hlidar');
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
