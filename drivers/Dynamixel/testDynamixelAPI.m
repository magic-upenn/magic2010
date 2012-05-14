dev  = '/dev/ttyUSB0';
baud = 1000000;
id1   = 4;

dynamixelAPI_1('connect',dev,baud,id1);
dynamixelAPI_1('setPosition',0,100);

while(1)
  dynamixelAPI_1('getPosition')
  pause(0.01);
end