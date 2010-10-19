SetMagicPaths;

xbeeDev = '/dev/ttyUSB0';
xbeeBaud = 115200;

XbeeAPI('connect',xbeeDev,xbeeBaud);

while(1)
  packets = XbeeAPI('receive');
  len = length(packets);
  if len > 0
    data=packets(1).data;
    
    %data that comes in is a dynamixel packet, so payload is data(6:end-1)
    stuff = deserialize(data(6:end-1))
  end
  pause(0.1)
end