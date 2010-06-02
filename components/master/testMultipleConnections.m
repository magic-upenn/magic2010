function testMultipleConnections
clear all

global ROBOTS
SetMagicPaths

nRobots=4;

for ii=1:nRobots
  %initialize the ids
  ROBOTS(ii).id     = ii;

  %initialize the ipcAPI function handles
  ROBOTS(ii).ipcAPI = str2func(sprintf('ipcAPI%d',ii));
  
  %specify ip address and (optionally) port 
  %in format 'xxx.xxx.xxx.xxx:port'
  ROBOTS(ii).addr   = 'localhost'; %sprintf('192.168.10.%d',ii+100);
end

for ii=1:length(ROBOTS)
  %use the a different ipcAPI for each robot
  %provide index as 3rd argument to generate unique name for each
  %connection
  ROBOTS(ii).ipcAPI('connect',ROBOTS(ii).addr,ii);
end


messages = {'Pose','GPS','HeartBeat','State'};
handles  = {@ipcRecvPoseFcn,@ipcRecvGpsFcn, ...
            @ipcRecvHeartBeatFcn,@ipcRecvStateFcn};
%subscribe to messages

for ii=1:length(ROBOTS)
  for jj=1:length(messages)
    msgName = sprintf('Robot%d/%s',ROBOTS(ii).id,messages{jj});
    ipcReceiveSetFcn(msgName,handles{jj},ROBOTS(ii).ipcAPI);
  end
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
fprintf(1,'got heartbeat message from robot %d\n',id);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%handle heartbeat messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvStateFcn(data,name)
global ROBOTS

id = GetIdFromName(name);
ROBOTS(id).state.data = deserialize(data);
fprintf(1,'got state message from robot %d\n',id);




