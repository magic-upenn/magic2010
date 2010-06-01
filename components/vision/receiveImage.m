function receiveImage

SetMagicPaths;
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

function ipcRecvImageFcn(msg)
fprintf(1,'got image\n');
imPacket = deserialize(msg)
im = djpeg(imPacket.jpg);
image(im);
drawnow;

function ipcRecvStaticOoiFcn(msg)
fprintf(1,'got static ooi\n');
r = deserialize(msg)

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