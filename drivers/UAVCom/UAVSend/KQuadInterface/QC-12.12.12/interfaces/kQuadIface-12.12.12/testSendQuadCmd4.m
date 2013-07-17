%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function testSendQuadCmd4()

%open the interface
KQUAD.dev    = '/dev/ttyUSB0';
KQUAD.driver = @kQuadInterfaceAPI;
KQUAD.baud   = 1000000;
KQUAD.id     = 1;
KQUAD.chan   = 1;
KQUAD.type   = 0; %0 for standard, 1 for nano

KQUAD.driver('connect',KQUAD.dev,KQUAD.baud)

while(1)
  
  thrust = 1; %grams. 1 for idle
  roll   = 0; %radians
  pitch  = 0; %radians
  yaw    = 0; %radians
  
  trpy = [thrust roll pitch yaw];
  
  drpy = [0 0 0];     %angular rates (rad/sec)
  kp   = [0 0 0];     %proportional gains
  kd   = [0 0 0];     %derivative gains
  ms   = [0 0 0];     %moments (x,y,z)

  KQUAD.driver('SendQuadCmd4',KQUAD.id, KQUAD.chan, KQUAD.type, ...
                trpy, drpy, kp, kd, ms);

  pause(0.03);
end
