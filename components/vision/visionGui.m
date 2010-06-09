function visionGui
SetMagicPaths
visionGuiInit;
visionGuiSetupFigure;

while(1)
  fprintf(1,'.');
    masterReceiveFromRobots(10);
    pause(0.05);
end


%initialize the gui variables
function visionGuiInit
global IMAGES STATIC_OOI ROBOTS

nRobots = 10;
ids = [1 2]; % list of ID's of available robots

for ii=1:nRobots
    IMAGES(ii).id = [];
    IMAGES(ii).t = [];
    IMAGES(ii).jpg = [];
    IMAGES(ii).Ymean = [];
    IMAGES(ii).POSE = [];
    STATIC_OOI(ii).OOI = [];
    STATIC_OOI(ii).id = [];
    STATIC_OOI(ii).t = [];
    STATIC_OOI(ii).POSE = [];
end

ipcInit;

masterConnectRobots(ids);

for ii=1:length(ROBOTS)
  if (ROBOTS(ii).connected == 1)
    ROBOTS(ii).ipcAPI('define',sprintf('Robot%d/CamParam',ii));
  end
end

messages = {'Image','StaticOOI'};
handles  = {@ipcRecvImageFcn,@ipcRecvStaticOoiFcn};

%subscribe to messages
masterSubscribeRobots(messages,handles,[1 1]);

%setup local IPC to send confirmed OOI to Mapping Console 
ipcAPIDefine('ConfirmedOOI');


% Set up the figure
function visionGuiSetupFigure
global GUI PLOTHANDLES 

figure(1), clf(gcf)

set(gcf,'NumberTitle','off','Name','Magic 2010 GUI Vision Station', ...
        'Position',[50 50 1500 840],'Toolbar','figure','KeyPressFcn',@confirmOOI);
      
GUI.hMan(1) = uicontrol('Position',[350 800 100 25],'String','Manual OOI','Callback',@manualOOI,'UserData',1);
GUI.hMan(2) = uicontrol('Position',[800 800 100 25],'String','Manual OOI','Callback',@manualOOI,'UserData',2);
GUI.hMan(3) = uicontrol('Position',[1250 800 100 25],'String','Manual OOI','Callback',@manualOOI,'UserData',3);

subplot(2,3,1); PLOTHANDLES(1) = image([]); axis equal; axis([1 256 1 192]); axis ij;
subplot(2,3,2); PLOTHANDLES(2) = image([]); axis equal; axis([1 256 1 192]); axis ij;
subplot(2,3,3); PLOTHANDLES(3) = image([]); axis equal; axis([1 256 1 192]); axis ij;
subplot(2,3,4); image([]); axis equal; axis([1 256 1 192]); axis ij;
subplot(2,3,5); image([]); axis equal; axis([1 256 1 192]); axis ij;
subplot(2,3,6); image([]); axis equal; axis([1 256 1 192]); axis ij;

set(PLOTHANDLES(1),'EraseMode','None');
set(PLOTHANDLES(2),'EraseMode','None');
set(PLOTHANDLES(3),'EraseMode','None');

uicontrol('Style','text','Position',[80 770 60 20],'FontSize',12, ...
          'String','Ymean');
uicontrol('Style','text','Position',[280 770 60 20],'FontSize',12, ...
          'String','targetY');
GUI.hYcurr(1) = uicontrol('Style','text','Position',[150 770 60 20],'FontSize',12, ...
          'String','0.5');
GUI.hYmean(1) = uicontrol('Style','edit','Position',[350 770 60 20],'FontSize',12, ...
          'String','0.5','Callback',@updateCam,'UserData',1);
GUI.hYcurr(2) = uicontrol('Style','text','Position',[600 770 60 20],'FontSize',12, ...
          'String','0.5');
GUI.hYmean(2) = uicontrol('Style','edit','Position',[800 770 60 20],'FontSize',12, ...
          'String','0.5','Callback',@updateCam,'UserData',2);
GUI.hYcurr(3) = uicontrol('Style','text','Position',[1050 770 60 20],'FontSize',12, ...
          'String','0.5');
GUI.hYmean(3) = uicontrol('Style','edit','Position',[1250 770 60 20],'FontSize',12, ...
          'String','0.5','Callback',@updateCam,'UserData',3);

GUI.hRobotXY(1) = uicontrol('Style','text','Position',[200 450 300 20],'FontSize',12, ...
          'String',sprintf('X:%s, Y:%s, yaw:%s','0.0','0.0','0.0'));
GUI.hRobotXY(2) = uicontrol('Style','text','Position',[620 450 300 20],'FontSize',12, ...
          'String',sprintf('X:%s, Y:%s, yaw:%s','0.0','0.0','0.0'));
GUI.hRobotXY(3) = uicontrol('Style','text','Position',[1050 450 300 20],'FontSize',12, ...
          'String',sprintf('X:%s, Y:%s, yaw:%s','0.0','0.0','0.0'));

GUI.hConfOOI(1) = uicontrol('Style','text','Position',[200 360 300 30],'FontSize',20, ...
          'String','Press "1" to confirm OOI','Visible','off');
GUI.hConfOOI(2) = uicontrol('Style','text','Position',[620 360 300 30],'FontSize',20, ...
          'String','Press "2" to confirm OOI','Visible','off');
GUI.hConfOOI(3) = uicontrol('Style','text','Position',[1050 360 300 30],'FontSize',20, ...
          'String','Press "3" to confirm OOI','Visible','off');


function ipcRecvImageFcn(msg,name)
global IMAGES PLOTHANDLES GUI
%fprintf(1,'got image name %s\n',name);
imPacket = deserialize(msg);
IMAGES(imPacket.id) = imPacket;
IMAGES(imPacket.id).jpg = djpeg(imPacket.jpg);
set(PLOTHANDLES(imPacket.id),'CData',IMAGES(imPacket.id).jpg);
set(GUI.hYcurr(imPacket.id),'String',num2str(imPacket.Ymean));
if isempty(imPacket.POSE)
    fprintf(1,'No POSE.data from Robot %d\n',imPacket.id);
    return
end
set(GUI.hRobotXY(imPacket.id),'String',sprintf('X:%s, Y:%s, yaw:%s',num2str(imPacket.POSE.x),num2str(imPacket.POSE.y),num2str(imPacket.POSE.yaw)));

%drawnow;

function ipcRecvStaticOoiFcn(msg,name)
global  IMAGES STATIC_OOI GUI
%fprintf(1,'got static ooi\n');
OOIpacket = deserialize(msg);
STATIC_OOI(OOIpacket.id) = OOIpacket;
subplot(2,3,OOIpacket.id+3);
imshow(IMAGES(OOIpacket.id).jpg); axis image;
hold on;
        BB = OOIpacket.OOI.BoundingBox;
        line([BB(1),BB(1)+BB(3)],[BB(2),BB(2)],'Color','g');
        line([BB(1)+BB(3),BB(1)+BB(3)],[BB(2),BB(2)+BB(4)],'Color','g');
        line([BB(1),BB(1)],[BB(2),BB(2)+BB(4)],'Color','g');
        line([BB(1),BB(1)+BB(3)],[BB(2)+BB(4),BB(2)+BB(4)],'Color','g');
        text(BB(1),BB(2),sprintf('%2.2f',OOIpacket.OOI.distance),'color','g');
        text(BB(1),BB(2)+BB(4),sprintf('%2.2f',OOIpacket.OOI.angle),'color','g');
hold off;
set(GUI.hConfOOI(OOIpacket.id),'Visible','on');
drawnow;

function manualOOI(hObj,eventdata)
id = get(hObj,'UserData');
%fprintf(1,'Clicked Manual OOI %d\n',id);
[xcrop,ycrop] = ginput(2);
rect = [min(xcrop) min(ycrop) abs(xcrop(1)-xcrop(2)) abs(ycrop(1)-ycrop(2))];
distance = GetDistfromYheight(abs(ycrop(1)-ycrop(2)))
centroid = [mean(xcrop) mean(ycrop)];
angle = atand((centroid(1)-256/2)/(72/44*256/2))
    confOOI.OOI.area = [];
    confOOI.OOI.centroid = centroid;
    confOOI.OOI.boundingBox = [];
    confOOI.OOI.BoundingBox = rect;
    confOOI.OOI.Extent = [];
    confOOI.OOI.Cr_mean = [];
    confOOI.OOI.distance = distance;
    confOOI.OOI.angle = angle;
    confOOI.OOI.redbinscore = [];
    confOOI.id = id;
    confOOI.t = [];
    confOOI.POSE = [];

    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
    disp('Confirmed OOI sent');

function confirmOOI(hObj,eventdata)
global STATIC_OOI GUI
if eventdata.Character == '1'
    confOOI = STATIC_OOI(1)
    set(GUI.hConfOOI(1),'Visible','off');
    subplot(2,3,4); image([]); axis equal; axis([1 256 1 192]); axis ij;
    ipcAPIPublish('ConfirmedOOI',serialize(confOOI));
    disp('Confirmed OOI sent');
end

function updateCam(hObj,eventdata)
    global ROBOTS
    id = get(hObj,'UserData');
    newYmean = str2double(get(hObj,'string'));
    if isnan(newYmean)
        errordlg('You must enter a numeric value','Bad Input','modal')
        return
    end
    ROBOTS(id).ipcAPI('publish',sprintf('Robot%d/CamParam',id),serialize(newYmean));
    