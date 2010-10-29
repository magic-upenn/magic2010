function magicGui
SetMagicPaths
magicGuiInit;
magicGuiSetupFigure;

while(1)
  magicGuiUpdate();
  pause(0.05)
end


%initialize the gui variables
function magicGuiInit
global ROBOT_CNTRL ROBOTS POSES IPC

nRobots = 10;

ROBOT_CNTRL.selected = -1;
ROBOT_CNTRL.nRobots  = nRobots;


for ii=1:nRobots
  POSES(ii).data = [];
  POSES(ii).H = eye(4);
end

ipcInit;
%{
for ii=1:nRobots
  IPC.ipcApiHandle(ii) = str2func(sprintf('ipcAPI%d',ii-1));
  IPC.ipcApiHandle(ii)('connect',
end
%}
for ii=0:nRobots-1
  %subscribe to pose messages of all robots
  ipcReceiveSetFcn(GetMsgName('Pose',ii), @ipcRecvPoseFcn);
  
  %define the outgoing messages
  ipcAPIDefine(sprintf('Robot%d/Traj',ii));
end

% Set up the figure
function magicGuiSetupFigure
global GUI ROBOT_CNTRL

figure(1), clf(gcf)

set(gcf,'NumberTitle','off','Name','Magic 2010 Gui', ...
        'Position',[100 100 500 400],'Toolbar','figure');
      
uicontrol('Style','text','Position',[0 320 60 40],'FontSize',12, ...
          'String','Robot Selector');
GUI.hRobSelGrp = uibuttongroup('Units','pixels','Position',[0 0 50 300], ...
                 'SelectionChangeFcn',@robotSelectorCallback);

nRobots = ROBOT_CNTRL.nRobots;
buttonSpacing = 25;
buttonStart   = 250;

for ii=0:nRobots-1
  uicontrol('Style','text','Position',[5 (buttonStart-ii*buttonSpacing) 20 20], ...
            'String',sprintf('%d',ii),'FontSize',12);
  GUI.hRobSel(ii+1) = uicontrol('Style','Radio','Parent',GUI.hRobSelGrp, ...
           'Position',[20 (buttonStart-ii*buttonSpacing) 20 20],'UserData',ii);
end

hold on;
GUI.hMap = plot(rand(10,1),rand(10,1),'.');
set(gcf,'WindowButtonUpFcn',@mouseClickCallback);
hold off;
set(gca,'Position',[0.2 0.2 0.7 0.7]);


%callback for the robot selector buttons
function robotSelectorCallback(obj, event)
global ROBOT_CNTRL POSES

ROBOT_CNTRL.selected = get(get(obj,'SelectedObject'),'UserData');




function ipcRecvPoseFcn(msg)
global POSES

if ~isempty(msg)
  pose = MagicPoseSerializer('deserialize',msg);
  POSES(pose.id+1).data = pose;
end

function magicGuiUpdate
global ROBOT_CNTRL USER_INPUT


if ~USER_INPUT.freshClick
  return;
end

id = ROBOT_CNTRL.selected;

if id < 0
  return;
end

USER_INPUT.freshClick = 0;

%convert the goal location into robot's local frame
Y = POSES(id+1).H * [USER_INPUT.y; USER_INPUT.x; 0; 1];

trajMsgName = sprintf('Robot%d/Traj',id);

traj.id   = id;
traj.size = 1;
traj.waypoints(1).x = Y(1);
traj.waypoints(1).y = Y(2);
ipcAPIPublish(trajMsgName,serialize(traj));
fprintf(1,'published traj\n');

