function MsgNames = initMessagingGC(robotId,ip)
SetMagicPaths;

%MsgNames.hmap = ['Robot' robotId '/IncMapUpdateH'];         % Horizontal Map Update
MsgNames.vmap = ['Robot' robotId '/IncMapUpdateV'];         % Vertical Map Update
MsgNames.pose = ['Robot' robotId '/Pose'];                  % Pose
MsgNames.path = ['Robot' robotId '/Planner_Path'];          % Path
MsgNames.ctrl = ['Robot' robotId '/VelocityCmd'];           % Control commands


% subscribe to messages
ipcAPIConnect(ip);
%ipcAPISubscribe(MsgNames.hmap);
ipcAPISubscribe(MsgNames.vmap);
ipcAPISubscribe(MsgNames.pose);
ipcAPISubscribe(MsgNames.path);
ipcAPISubscribe(MsgNames.ctrl);


% define messages
%ipcAPIDefine(MsgNames.hmap);
ipcAPIDefine(MsgNames.vmap);
ipcAPIDefine(MsgNames.pose,MagicPoseSerializer('getFormat'));
ipcAPIDefine(MsgNames.path);
ipcAPIDefine(MsgNames.ctrl,MagicVelocityCmdSerializer('getFormat'));

%DefineSensorMessages(str2double(robotId),ip);

end
