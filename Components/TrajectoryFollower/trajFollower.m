function trajFollower(tUpdate)

if nargin < 1,
  tUpdate = 0.001;
end

trajFollowerStart;

loop = 1;
while (loop),
  pause(tUpdate);
  trajFollowerUpdate;
end

trajFollowerStop;


function trajFollowerStart
global TRAJ
addpath( [ getenv('VIS_DIR') '/ipc' ] )
robotIdStr = getenv('ROBOT_ID');
if isempty(robotIdStr)
  error('robot id is not defined in an environment variable');
end

%connect to ipc
TRAJ.ipcMsgName = ['Robot' robotIdStr '/Trajectory'];
ipcAPIConnect();
ipcAPISubscribe(TRAJ.ipcMsgName);



function trajFollowerUpdate
global TRAJ
msgs = ipcAPIReceive(25);
len = length(msgs);
if len > 0
  for i=1:len
    msg = msgs(i);
    switch msg.name
      case TRAJ.ipcMsgName
        fprintf(1,'got traj message\n');
        TRAJ.traj    = MagicTrajectorySerializer('deserialize',msg.data);
        TRAJ.nextInd = 1;
      otherwise
        fprintf(1,'got unknown message type: %s \n',msg.name);
    end
  end
end

trajFollowerFollow;




function trajFollowerFollow
global TRAJ








