function Rascalmainstatemch(tUpdate)
%close all;
%SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');
if nargin < 1,
  tUpdate = 0.05;
end

global MP
% Construct state machine:
MP.sm = statemch('sInitial', ...
                 'sWait', ...
                 'sScan', ...
                 'sPlan' ...
                 );

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sWait' ...                                
                             );
MP.sm = setTransition(MP.sm, 'sWait', ...
                             'scan', 'sScan', ...      
                             'goToPoint','sScan',...
                             'stop','sWait'...
                             );
MP.sm = setTransition(MP.sm, 'sScan', ...
                             'plan', 'sPlan', ...  
                             'goToPoint','sScan',...
                             'stop','sWait'...
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

global MP SERVO_ANGLE POSE LIDAR LFLAG QUEUELASER MAP GOAL LAST_STATE BATTERY 

MP.sm = entry(MP.sm);

LAST_STATE = '';
SERVO_ANGLE = 0;
QUEUELASER = false;
LFLAG = false;
LIDAR = {};
GOAL = [];
BATTERY = [];
POSE.x = 0;
POSE.y = 0;
POSE.yaw = 0;
POSE.pitch = 0;
POSE.roll = 0;
MAP = init_map(0.05,15,15);
MP.nupdate = 0;

%robotId = '5';

% Initilize IPC
ipcInit;
ipcReceiveSetFcn(GetMsgName('BatteryStatus'), @RascalmapfsmRecvBatteryFcn);
ipcReceiveSetFcn(GetMsgName('Pose'), @RascalmapfsmRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Goal_Point'), @RascalmapfsmRecvGoalPointFcn);
ipcReceiveSetFcn(GetMsgName('Lidar0'), @RascalmapfsmRecvLidarScansFcn);
ipcReceiveSetFcn(GetMsgName('Servo1'), @RascalmapfsmRecvServoFcn);
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
servoCmd.speed        = 15;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);

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

if ~isempty(POSE) && mode(MP.nupdate,200) == 0
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
