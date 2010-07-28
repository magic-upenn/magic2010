dev  = '/dev/ttyUSB1';
baud = 1000000;
id1   = 1;
id2   = 4;

dynamixelAPI_1('connect',dev,baud,id1);
dynamixelAPI_2('connect',dev,baud,id2);

dynamixelAPI_1('setPosition',0,100);
dynamixelAPI_2('setPosition',0,100);

while(1)
  dynamixelAPI_1('getPosition')
  dynamixelAPI_2('getPosition')
  pause(0.01);
end