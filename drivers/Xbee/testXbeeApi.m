function testXbeeAPi
global ROBOT_CNTRL


xbeeDev = '/dev/ttyUSB0';
xbeeBaud = 115200;

XbeeAPI('connect',xbeeDev,xbeeBaud);

joyDev = '/dev/input/event6';
JoystickLogitechX3dAPI('connect',joyDev);

CreateGui;
ROBOT_CNTRL.selected = -1;

while(1)
  [v w] = JoystickLogitechX3dAPI('getCmd');
  v = v/4;
  w = w/4;
  if (ROBOT_CNTRL.selected > 0)
    XbeeAPI('writeVelCmd',int8([v w]),ROBOT_CNTRL.selected);
  end
  pause(0.025)
end



function CreateGui
global GUI ROBOT_CNTRL

nRobots = 10;

ROBOT_CNTRL.selected = -1;
ROBOT_CNTRL.nRobots  = nRobots;

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

for ii=1:nRobots
  uicontrol('Style','text','Position',[5 (buttonStart-ii*buttonSpacing) 20 20], ...
            'String',sprintf('%d',ii),'FontSize',12);
  GUI.hRobSel(ii+1) = uicontrol('Style','Radio','Parent',GUI.hRobSelGrp, ...
           'Position',[20 (buttonStart-ii*buttonSpacing) 20 20],'UserData',ii);
end

%callback for the robot selector buttons
function robotSelectorCallback(obj, event)
global ROBOT_CNTRL

ROBOT_CNTRL.selected = get(get(obj,'SelectedObject'),'UserData');

