SetMagicPaths
addpath ../Xbee/

addr = '192.168.10.19';
port = 12345;

width = 160;
height = 120;
UdpReceiveAPI('connect',addr,port);


nRobots = 6;

figure(1); clf(gcf);
hs=[];

for ii=1:nRobots
  subplot(1,nRobots,ii);
  hs(ii) = image(zeros(height,width,3,'uint8'));
  set(gca,'ydir','normal');
end

drawnow

while(1)
  packets = UdpReceiveAPI('receive');
  n = length(packets);
  
  if n > 0
    for ii=1:n
      imPacket = deserialize(packets(ii).data);
      im = djpeg(imPacket.jpg);
      id = imPacket.robotId;
      set(hs(id),'cdata',im); drawnow;
    end
  end
  pause(0.01);
end