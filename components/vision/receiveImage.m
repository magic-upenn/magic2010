function receiveImage
clear all

global ROBOTS
SetMagicPaths

figure(1);
%h1 = subplot(1,3,1);
%set(h1, 'ButtonDownFcn', @RedAcknowledge)

ids=[1 3];

masterConnectRobots(ids);

disp('connected');

messages = {'Image','StaticOOI'};
handles  = {@ipcRecvImageFcn,@ipcRecvStaticOoiFcn};

%subscribe to messages
masterSubscribeRobots(messages,handles,[10 10]);

while(1)
  %listen to messages 10ms at a time (frome each robot)
  fprintf(1,'?');
  masterReceiveFromRobots(10);
  fprintf(1,'.');
end



function ipcRecvImageFcn(msg,name)

fprintf(1,'got image name %s\n',name);
imPacket = deserialize(msg);
im = djpeg(imPacket.jpg);
subplot(1,3,imPacket.id);image(im); axis image;
drawnow;


function ipcRecvStaticOoiFcn(msg,name)
fprintf(1,'got static ooi\n');
r = deserialize(msg);
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

function RedAcknowledge(hObject, eventdata)
%hFig = get(hObject, 'Children');
disp('Clicked in subplot')


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