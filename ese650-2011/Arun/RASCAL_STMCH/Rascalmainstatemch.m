function Rascalmainstatemch(tUpdate)
%close all;
clear persistent
SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');
if nargin < 1,
  tUpdate = 0.05;
end

global MP
% Construct state machine:
MP.sm = statemch('sInitial_R', ...
                 'sWait_R', ...
                 'sScan_R', ...
                 'sFollow_R' ...
                 );

MP.sm = setTransition(MP.sm, 'sInitial_R', ...
                             'Pose', 'sWait_R' ... 
                             );
MP.sm = setTransition(MP.sm, 'sWait_R', ...
                             'Scan', 'sScan_R', ...      
                             'goToPoint','sScan_R',...
                             'Stop','sWait_R'...
                             );
MP.sm = setTransition(MP.sm, 'sScan_R', ...
                             'goToPoint','sScan_R',...
                             'Traj','sFollow_R',...
                             'Stop','sWait_R'...
                             );
MP.sm = setTransition(MP.sm, 'sFollow_R', ...
                             'goToPoint','sScan_R',...
                             'Stop','sWait_R',...
                             'Dist','sScan_R',...
                             'Timeout','sWait_R',...
                             'Done','sWait_R'...
                             );
mapfsmEntry;

loop = 1;
while (loop),
  pause(tUpdate);
  mapfsmUpdate;
end

mapfsmExit;

end

function mapfsmEntry

global MP SERVO_ANGLE POSE LIDAR LFLAG QUEUELASER GOAL LAST_STATE BATTERY PATH 
global MAP START_MAP

MP.sm = entry(MP.sm);

LAST_STATE = '';
SERVO_ANGLE = 0;
QUEUELASER = false; 
START_MAP = true;% Just to get an initial map of the surroundings
LFLAG = false;
LIDAR = {};
GOAL = [];
BATTERY = [];
PATH = [];

init_map(0.05,30,30);
MP.nupdate = 0;

%temp = meters2cells([0 0],[MAP.xmin,MAP.ymin],MAP.res);

% POSE.x = temp(1); % column value
% POSE.y = temp(2); % row value
% POSE.yaw = 0;
% POSE.pitch = 0;
% POSE.roll = 0;
POSE = [];


%robotId = '5';

% Initilize IPC
ipcInit;
ipcReceiveSetFcn(GetMsgName('BatteryStatus'), @RascalmapfsmRecvBatteryFcn);
ipcReceiveSetFcn(GetMsgName('Pose'), @RascalmapfsmRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Goal_Point'), @RascalmapfsmRecvGoalPointFcn);
ipcReceiveSetFcn(GetMsgName('Lidar0'), @RascalmapfsmRecvLidarScansFcn);
ipcReceiveSetFcn(GetMsgName('Servo1'), @RascalmapfsmRecvServoFcn);
%ipcReceiveSetFcn(GetMsgName('Mapupdate'), @RascalmapfsmRecvIncMapUpdateVFcn);
ipcReceiveSetFcn(GetMsgName('Path'), @RascalmapfsmRecvPlannerPathFcn);
%ipcReceiveSetFcn(GetMsgName('ImuFiltered'), @RascalmapfsmRecvImuFcn);

ipcAPIDefine(GetMsgName('FSM_Status'));
% Servo stuff
servoMsgName = GetMsgName('Servo1Cmd');
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));

% First bring the servo to zero angle position
servoCmd.id           = 1;
servoCmd.mode         = 2;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = 0;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 20;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
disp('Hi')
end

%==========
function mapfsmUpdate

global MP
global POSE MAP
global LAST_STATE SERVO_ANGLE BATTERY

persistent lastStatusTime

if isempty(lastStatusTime)
  lastStatusTime = gettime;
end

MP.nupdate = MP.nupdate + 1;

% Check IPC messages
ipcReceiveMessages;

MP.sm = update(MP.sm);

%if the state has changed send a status message to the GCS
if ~strcmp(currentState(MP.sm),LAST_STATE) || (gettime - lastStatusTime > 1.0)
  msg.status = [currentState(MP.sm) sprintf(' %.1fV', BATTERY)];
  msg.servo = SERVO_ANGLE;
  msg.id = GetRobotId();
  ipcAPIPublish(GetMsgName('FSM_Status'), serialize(msg));
  lastStatusTime = gettime;
end
LAST_STATE = currentState(MP.sm);

if ~isempty(POSE) && mode(MP.nupdate,10) == 0
    imagesc(MAP.map)
    hold on
    cpose = meters2cells_cont([POSE.x,POSE.y],[MAP.xmin,MAP.ymin],MAP.res);
    plot(cpose(1),cpose(2),'r*');
    colormap jet
    drawnow
end

end

%==========
function mapfsmExit

global MP

MP.sm = exit(MP.sm);
end
