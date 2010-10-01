SetMagicPaths
addpath ../Xbee/

addr = '192.168.10.102';
port = 12345;

UdpReceiveAPI('connect',addr,port);


while(1)
  packets = UdpReceiveAPI('receive');
  n = length(packets);
  
  if n > 0
    for ii=1:n
      imPacket = deserialize(packets(ii).data);
      im = djpeg(imPacket.jpg);
      image(im); drawnow;
    end
  end
  pause(0.01);
end