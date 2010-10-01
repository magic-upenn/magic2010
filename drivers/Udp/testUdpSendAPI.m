addr = '127.0.0.1';
port = 12345;

UdpSendAPI('connect',addr,port);

cntr = 1;
while(1)
  data = uint8(sprintf('asdf%d',cntr));
  UdpSendAPI('send',data);
  pause(0.5);
  cntr = cntr +1;
end