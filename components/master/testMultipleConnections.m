function testMultipleConnections
clear all

global ROBOTS
SetMagicPaths

ids=[1 3];

masterConnectRobots(ids);

messages = {'Pose','GPS','HeartBeat','State'};
handles  = {@ipcRecvPoseFcn,@ipcRecvGpsFcn, ...
            @ipcRecvHeartBeatFcn,@ipcRecvStateFcn};

%subscribe to messages
masterSubscribeRobots(messages,handles);

while(1)
  %listen to messages 10ms at a time (frome each robot)
  masterReceiveFromRobots(10);
  pause(0.1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%handle pose messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvPoseFcn(data,name)
global ROBOTS

id = GetIdFromName(name);
ROBOTS(id).pose.data = MagicPoseSerializer('deserialize',data);
fprintf(1,'got pose message from robot %d\n',id);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%handle gps messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvGpsFcn(data,name)
global ROBOTS

id = GetIdFromName(name);
ROBOTS(id).gps.data = MagicGpsASCIISerializer('deserialize',data);
fprintf(1,'got gps message from robot %d\n',id);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%handle heartbeat messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvHeartBeatFcn(data,name)
global ROBOTS

id = GetIdFromName(name);
ROBOTS(id).heartbeat.data = MagicHeartBeatSerializer('deserialize',data);
data = ROBOTS(id).heartbeat.data
fprintf(1,'got heartbeat message from robot %d\n',id);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%handle heartbeat messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvStateFcn(data,name)
global ROBOTS

id = GetIdFromName(name);
ROBOTS(id).state.data = deserialize(data);
fprintf(1,'got state message from robot %d\n',id);




