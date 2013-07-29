%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function testSendQuadCmd3()

%open the interface
KQUAD.dev    = '/dev/ttyUSB0';
KQUAD.driver = @kQuadInterfaceAPI;
KQUAD.baud   = 1000000;
KQUAD.id     = 1;
KQUAD.chan   = 1;
KQUAD.type   = 1; %0 for standard, 1 for nano

KQUAD.driver('connect',KQUAD.dev,KQUAD.baud)

while(1)
  
  thrust = 1; %grams. 1 for idle
  roll   = 0; %radians
  pitch  = 0; %radians
  yaw    = 0; %radians
  
  trpy = [thrust roll pitch yaw];
  
  drpy = [0 0 0];     %angular rates (rad/sec)
  kp   = 0*[400 400 470];     %proportional gains
  kd   = 0*[30 30 50];     %derivative gains

  KQUAD.driver('SendQuadCmd3',KQUAD.id, KQUAD.chan, KQUAD.type, ...
               trpy, drpy, kp, kd);

  pause(0.03);
end
