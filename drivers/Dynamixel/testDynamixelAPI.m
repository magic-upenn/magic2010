dev  = '/dev/ttyUSB0';
baud = 1000000;
id   = 1;

dynamixelAPI('connect',dev,baud,id);

dynamixelAPI('setPosition',30,100);

while(1)
  dynamixelAPI('getPosition')
  pause(0.01);
end