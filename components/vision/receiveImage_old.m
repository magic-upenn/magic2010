function receiveImage

global STATIC_OOI

for ii=1:10
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
end
SetMagicPaths

figure(1);
confbutton3 = uicontrol('Position',[1200 380 100 25],'String','Confirm OOI','Callback','confirmOOI3');
manual3 = uicontrol('Position',[1400 380 100 25],'String','Manual OOI','Callback','manualOOI3');

ids=[3];

masterConnectRobots(ids);

messages = {'Image','StaticOOI'};
handles  = {@ipcRecvImageFcn,@ipcRecvStaticOoiFcn};

%subscribe to messages
masterSubscribeRobots(messages,handles,[10 10]);

while(1)
  %listen to messages 10ms at a time (frome each robot)
%  fprintf(1,'?');
  masterReceiveFromRobots(10);
%  fprintf(1,'.');
end



function ipcRecvImageFcn(msg,name)

%fprintf(1,'got image name %s\n',name);
imPacket = deserialize(msg);
im = djpeg(imPacket.jpg);
subplot(1,3,imPacket.id);image(im); axis image;
drawnow;


function ipcRecvStaticOoiFcn(msg,name)
global STATIC_OOI
%fprintf(1,'got static ooi\n');
r = deserialize(msg);
STATIC_OOI(3) = r;
subplot(1,3,r.id);
hold on;
        line([r.BoundingBox(1),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2),r.BoundingBox(2)],'Color','g');
        line([r.BoundingBox(1)+r.BoundingBox(3),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        line([r.BoundingBox(1),r.BoundingBox(1)],[r.BoundingBox(2),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        line([r.BoundingBox(1),r.BoundingBox(1)+r.BoundingBox(3)],[r.BoundingBox(2)+r.BoundingBox(4),r.BoundingBox(2)+r.BoundingBox(4)],'Color','g');
        text(r.BoundingBox(1),r.BoundingBox(2),sprintf('%2.2f',r.distance),'color','g');
        text(r.BoundingBox(1),r.BoundingBox(2)+r.BoundingBox(4),sprintf('%2.2f',r.angle),'color','g');
hold off;
drawnow;

function confirmOOI3()
global STATIC_OOI
disp('Clicked Confirm OOI');
STATIC_OOI(3)

function manualOOI3()
disp('Clicked manual OOI');

%{
ipcInit('192.168.10.101');

nRobots = 1;
ids = [1];
for i=1:nRobots
    ROBOTS(i).imageMsgName       = sprintf('Robot%d/Image',ids(i));
    ROBOTS(i).staticOoiMsgName   = sprintf('Robot%d/StaticOOI',ids(i));
    ipcReceiveSetFcn(ROBOTS(i).imageMsgName, @ipcRecvImageFcn);
    ipcReceiveSetFcn(ROBOTS(i).staticOoiMsgName, @ipcRecvStaticOoiFcn);
end

while(1)
    ipcReceiveMessages(10);
end
%}


%{
ipcAPISubscribe('Robot1/Image');
ipcAPISubscribe('Robot1/StaticOOI');


while(1)
   msgs = ipcAPIReceive(10);
   
   len = length(msgs);
   
   for i=1:len
      switch msgs(i).name
          case 'Robot1/Image'
              fprintf(1,'got image\n');
              imPacket = deserialize(msgs(i).data)
              im = djpeg(imPacket.jpg);
              image(im);
              drawnow;
          case 'Robot1/StaticOOI'
              fprintf(1,'got static ooi\n');
              r = deserialize(msgs(i).data)
      end
   end
    
end
%}