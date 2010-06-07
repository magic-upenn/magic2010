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
ids=[1]; % list of ID's of available robots

for ii=1:nRobots
    IMAGES(ii).id = [];
    IMAGES(ii).t = [];
    IMAGES(ii).jpg = [];
    IMAGES(ii).Ymean = [];
    STATIC_OOI(ii).area = [];
    STATIC_OOI(ii).centroid = [];
    STATIC_OOI(ii).boundingBox = [];
    STATIC_OOI(ii).BoundingBox = [];
    STATIC_OOI(ii).Extent = [];
    STATIC_OOI(ii).Cr_mean = [];
    STATIC_OOI(ii).distance = [];
    STATIC_OOI(ii).angle = [];
    STATIC_OOI(ii).redbinscore = [];
    STATIC_OOI(ii).id = [];
    STATIC_OOI(ii).t = [];
    STATIC_OOI(ii).x = [];
    STATIC_OOI(ii).y = [];
    STATIC_OOI(ii).z = [];
    STATIC_OOI(ii).v = [];
    STATIC_OOI(ii).w = [];
    STATIC_OOI(ii).roll = [];
    STATIC_OOI(ii).pitch = [];
    STATIC_OOI(ii).yaw = [];
end

%ipcInit;

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

% Set up the figure
function visionGuiSetupFigure
global GUI PLOTHANDLES 

figure(1), clf(gcf)

set(gcf,'NumberTitle','off','Name','Magic 2010 GUI Vision Station', ...
        'Position',[50 50 1500 840],'Toolbar','figure','KeyPressFcn',@confirmOOI);
      
%GUI.hConf1 = uicontrol('Position',[150 800 100 25],'String','OOI data','Callback',@showOOI,'UserData',1);
GUI.hMan(1) = uicontrol('Position',[350 800 100 25],'String','Manual OOI','Callback',@manualOOI,'UserData',1);
%GUI.hConf2 = uicontrol('Position',[600 800 100 25],'String','OOI data','Callback',@showOOI,'UserData',2);
GUI.hMan(2) = uicontrol('Position',[800 800 100 25],'String','Manual OOI','Callback',@manualOOI,'UserData',2);
%GUI.hConf3 = uicontrol('Position',[1050 800 100 25],'String','OOI data','Callback',@showOOI,'UserData',3);
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
          'String','0.5','Callback',@updateCam1);
GUI.hYcurr(2) = uicontrol('Style','text','Position',[600 770 60 20],'FontSize',12, ...
          'String','0.5');
GUI.hYmean(2) = uicontrol('Style','edit','Position',[800 770 60 20],'FontSize',12, ...
          'String','0.5','Callback',@updateCam2);
GUI.hYcurr(3) = uicontrol('Style','text','Position',[1050 770 60 20],'FontSize',12, ...
          'String','0.5');
GUI.hYmean(3) = uicontrol('Style','edit','Position',[1250 770 60 20],'FontSize',12, ...
          'String','0.5','Callback',@updateCam3);


function ipcRecvImageFcn(msg,name)
global IMAGES PLOTHANDLES GUI
%fprintf(1,'got image name %s\n',name);
imPacket = deserialize(msg);
IMAGES(imPacket.id) = imPacket;
IMAGES(imPacket.id).jpg = djpeg(imPacket.jpg);
set(PLOTHANDLES(imPacket.id),'CData',IMAGES(imPacket.id).jpg);
set(GUI.hYcurr(imPacket.id),'String',num2str(imPacket.Ymean));

%drawnow;

function ipcRecvStaticOoiFcn(msg,name)
global  IMAGES STATIC_OOI
%fprintf(1,'got static ooi\n');
r = deserialize(msg);
STATIC_OOI(r.id) = r;
subplot(2,3,r.id+3);
imshow(IMAGES(r.id).jpg); axis image;
hold on;
        line([r.BoundingBox(1),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2),r.BoundingBox(2)],'Color','g');
        line([r.BoundingBox(1)+r.BoundingBox(3),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        line([r.BoundingBox(1),r.BoundingBox(1)],[r.BoundingBox(2),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        line([r.BoundingBox(1),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2)+r.BoundingBox(4),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        text(r.BoundingBox(1),r.BoundingBox(2),sprintf('%2.2f',r.distance),'color','g');
        text(r.BoundingBox(1),r.BoundingBox(2)+r.BoundingBox(4),sprintf('%2.2f',r.angle),'color','g');
hold off;
drawnow;

% function showOOI(hObj,eventdata)
% global STATIC_OOI
% id = get(hObj,'UserData');
% STATIC_OOI(id)

function manualOOI(hObj,eventdata)
id = get(hObj,'UserData');
fprintf(1,'Clicked Manual OOI %d\n',id);
[xcrop,ycrop] = ginput(2);
rect = [min(xcrop) min(ycrop) abs(xcrop(1)-xcrop(2)) abs(ycrop(1)-ycrop(2))]
distance = GetDistfromYheight(abs(ycrop(1)-ycrop(2)))

function confirmOOI(hObj,eventdata)
global STATIC_OOI
if eventdata.Character == '1'
    STATIC_OOI(1)
    subplot(2,3,4); image([]); axis equal; axis([1 256 1 192]); axis ij;
end

function updateCam1(hObj,eventdata)
    global ROBOTS
    newYmean = str2double(get(hObj,'string'));
    if isnan(newYmean)
        errordlg('You must enter a numeric value','Bad Input','modal')
        return
    end
    ROBOTS(1).ipcAPI('publish','Robot1/CamParam',serialize(newYmean));
    
function updateCam3(hObj,eventdata)
    global ROBOTS
    newYmean = str2double(get(hObj,'string'));
    if isnan(newYmean)
        errordlg('You must enter a numeric value','Bad Input','modal')
        return
    end
    ROBOTS(3).ipcAPI('publish','Robot3/CamParam',serialize(newYmean));
