function magicGui

magicGuiInit;
magicGuiSetupFigure;

while(1)
  magicGuiUpdate();
  pause(0.1)
end


function magicGuiSetupFigure
global GUI

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
hold off;
set(gca,'Position',[0.2 0.2 0.7 0.7]);


function robotSelectorCallback(obj, event)
global ROBOT_CNTRL

ROBOT_CNTRL.selected = get(get(obj,'SelectedObject'),'UserData');

function magicGuiInit
global ROBOT_CNTRL

ROBOT_CNTRL.selected = -1;
ROBOT_CNTRL.nRobots  = 10;

ipcInit;

%subscribe to all the pose messages
for ii=0:ROBOT_CNTRL.nRobots-1
  ipcReceiveSetFcn(GetMsgName('Pose',ii), @ipcRecvPoseFcn);
end


function ipcRecvPoseFcn(msg)

if ~isempty(msg)
  pose = MagicPoseSerializer('deserialize',msg);
end

function magicGuiUpdate
global ROBOT_CNTRL

if ROBOT_CNTRL.selected >= 0
  
  
end

