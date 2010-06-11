function receiveTracks
global ROBOTS


SetMagicPaths;

setenv('ROBOT_ID','2');

ids=[2];

masterConnectRobots(ids);

messages = {'VelTracks','PoseExternal'};
handles  = {@VelTracksMsgHandler,@PoseMsgHandler};
          
queueLengths = [5 5];

%subscribe
masterSubscribeRobots(messages,handles,queueLengths);

velMsgName      = 'Robot2/VelocityCmd';
ROBOTS(2).ipcAPI('define',velMsgName,MagicVelocityCmdSerializer('getFormat'));

while(1)
  masterReceiveFromRobots(); %will return without blocking
  pause(0.1);
end


function PoseMsgHandler(data,name)
global RPOSE ROBOTS

id = GetIdFromName(name);
RPOSE(id).data = MagicPoseSerializer('deserialize',data);

function VelTracksMsgHandler(data,name)
global RPOSE ROBOTS

id = GetIdFromName(name);
tracks = deserialize(data)


hVels = [];

if ~isempty(tracks) && length(tracks.xs) > 0
  hVels = quiver(tracks.xs,tracks.ys,tracks.vxs,tracks.vys,0,'g');
  axis([-20 20 -20 20]);
  drawnow;
  disp('got tracks');
  
  angle = atan2(tracks.ys(1),tracks.ys(1));
  
  %{
  if isempty(RPOSE)
    return
  end
  
  vcmd.t = GetUnixTime();
  vcmd.v = 0;
  vcmd.w = 0;
  vcmd.vCmd = 0;
  vcmd.wCmd = 100*(angle - RPOSE(id).data.yaw)

  content = MagicVelocityCmdSerializer('serialize',vcmd);
  ROBOTS(id).ipcAPI('publishVC','Robot2/VelocityCmd',content);
  %}
else
  delete(hVels);
  drawnow;
end