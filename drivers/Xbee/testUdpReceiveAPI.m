addr = '127.0.0.1';
port = 12345;

UdpReceiveAPI('connect',addr,port);


while(1)
  UdpReceiveAPI('receive')
  pause(2.3);
end