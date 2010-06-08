function drive(tUpdate)

if nargin < 1,
  tUpdate = 0.1;
end

driveEntry;

loop = 1;
while (loop),
  pause(tUpdate);
  driveUpdate;
end

driveExit;

%==========
function driveEntry

% Initial setup:

global DRIVE POSE
global DATA

more off;

DATA.turnMode = 0;
DATA.tPredict = 0.1;
DATA.nupdate = 0;
DATA.nplot = 10;
DATA.t0 = clock;

POSE.data = [];

DRIVE.cmd = [];
DRIVE.path = [];
DRIVE.speed = 0;

% Initialize IPC
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'), @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Drive'), @ipcRecvDriveFcn);

%==========
function driveUpdate

global POSE DRIVE
global DATA

DATA.nupdate = DATA.nupdate+1;

% Check IPC messages
ipcReceiveMessages;

DRIVE.path = [1 0];
DRIVE.speed = 1;

if isempty(POSE.data),
  SetVelocity(0, 0);
  return;
end

if isfield(DRIVE, 'cmd') && ~isempty(DRIVE.cmd)
  SetVelocity(DRIVE.cmd(1), DRIVE.cmd(2));
  return;
end

if isempty(DRIVE.path)
  SetVelocity(0,0);
  return;
end

[xNear, yNear, aNear] = pathClosestPoint(DRIVE.path, [POSE.data.x POSE.data.y]);
dHeading = modAngle(aNear-POSE.data.yaw);
if abs(dHeading) > 45*pi/180,
  if (dHeading > 0),
    SetVelocity(0, .5);
  else
    SetVelocity(0, -.5);
  end
  return;
end

[turnPath, cost] = turnControl(DRIVE.path, POSE.data);
v = DRIVE.speed;
w = turnPath*max(v, 0.1);
disp(sprintf('drive: %.4f %.4f',v,w));
SetVelocity(v, w);


%==========
function driveStop

SetVelocity(0, 0);
