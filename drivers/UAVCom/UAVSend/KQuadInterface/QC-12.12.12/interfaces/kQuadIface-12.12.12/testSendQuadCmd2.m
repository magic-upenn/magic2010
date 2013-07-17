%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function testSendQuadCmd2()

%open the interface
KQUAD.dev    = '/dev/ttyUSB0';
KQUAD.driver = @kQuadInterfaceAPI;
KQUAD.baud   = 1000000;
KQUAD.id     = 1;
KQUAD.chan   = 1;
KQUAD.type   = 0; %0 for standard, 1 for nano

KQUAD.driver('connect',KQUAD.dev,KQUAD.baud);


while(1)
  rpm = [3000 3000 3000 3000]; %four rpm for the motors
  
  KQUAD.driver('SendQuadCmd2',KQUAD.id, KQUAD.chan, KQUAD.type, rpm);

  pause(0.03);
end
