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
DATA.nupdate = 0;
DATA.nplot = 10;
DATA.t0 = clock;

DRIVE.cmd = [];
DRIVE.path = [];
DRIVE.speed = 0;

% Initialize IPC
ipcInit;
ipcReceveSetFcn(GetMsgName('Pose'), @ipcRecvPoseFcn);

% Initialize SPREAD
spreadInit;
spreadReceiveSetFcn([gethostname '_Drive', @spreadRecvDriveFcn);

%==========
function driveUpdate

global POSE DRIVE
global DATA

DATA.nupdate = DATA.nupdate+1;

% Check Spread messages
spreadReceiveMessages;
% Check IPC messages
ipcReceiveMessages;

if isempty(POSE),
  SetVelocity(0, 0);
  return;
end

if ~isempty(DRIVE.cmd)
  SetVelocity(DRIVE.cmd(1), DRIVE.cmd(2));
  return;
end

return;

%{
t0 = clock;
PATHFOLLOW.dt = etime(t0, PATHFOLLOW.t0);
PATHFOLLOW.t0 = clock;

if isempty(POSE),
  spreadSendDrive('gasbrake', -0.3);
  return;
end

POSE = posePredict(POSE, PATHFOLLOW.dt);

if ~isempty(PATH.direction),
  dirPath = PATH.direction;
else
  dirPath = 0;
end
if ~isempty(PATH.speed),
  speedPath = PATH.speed;
else
  speedPath = 0;
end

if etime(clock, POSE.clock) > 1.0,
  disp('Stale POSE message: setting speed to zero');
  speedPath = 0;
end

if etime(clock, PATH.clock) > 1.0,
  disp('Stale PATH message: setting speed to zero');
  speedPath = 0;
end


% Check shift state
if (dirPath < 0) && (PATHFOLLOW.direction > 0),
  spreadSendDrive('shift reverse');
  PATHFOLLOW.direction = dirPath;
elseif (dirPath > 0) && (PATHFOLLOW.direction < 0),
  spreadSendDrive('shift drive');
  PATHFOLLOW.direction = dirPath;
elseif rem(PATHFOLLOW.nupdate, 20) == 0,
  % Periodically send current shift command
  if PATHFOLLOW.direction > 0,
    spreadSendDrive('shift drive');
  elseif PATHFOLLOW.direction < 0,
    spreadSendDrive('shift reverse');
  end
end


if ~isempty(PATH.turn),
  % Explicit turn command
  turnPath = PATH.turn;
elseif ~isempty(PATH.northing),
  % Path following:
  p = [PATH.northing(:) PATH.easting(:)];

  [turnPath, cost] = turnControl(p, POSE, PATHFOLLOW.direction);

  % Slow down if not on trajectory
  costFactor = 0.1 + 0.9*exp(-max(cost - 4.0, 0));
  speedPath = costFactor*speedPath;

  % Speed constraint from path curvature:
  [curv, len] = pathCurvature(PATH.northing(:), PATH.easting(:));
  len = max(len, 0.1);
  accelMax = 1.4;
  rTurn = 4.8;
  curvAbs = min(abs(curv), 1/rTurn);
  curvSpeed = sqrt(accelMax./max(curvAbs, 0.001));
  slowAccel = 0.5;
  speedCurv = min(sqrt(curvSpeed.^2 + 2*slowAccel*len));
  speedCurv = max(speedCurv, sqrt(accelMax*rTurn));
  speedPath = min(speedPath, speedCurv);

else
  turnPath = 0;
end
%}


%==========
function driveStop

SetVelocity(0, 0);
