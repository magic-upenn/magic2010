%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function testSendQuadCmd1()

%open the interface
KQUAD.dev    = '/dev/ttyUSB0';
KQUAD.driver = @kQuadInterfaceAPI;
KQUAD.baud   = 921600;
KQUAD.id     = 0;
KQUAD.chan   = 0;
KQUAD.type   = 1; %0 for standard, 1 for nano

KQUAD.driver('connect',KQUAD.dev,KQUAD.baud)
while(1)
  thrust = 1; %grams. 1 for idle
  roll   = 0; %radians
  pitch  = 0; %radians
  yaw    = 0; %radians
  
  trpy = [thrust roll pitch yaw];
  
  KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
  fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
  pause(0.03);
end
    