%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Servo1 message handler 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessServo1(data,name)
global SERVO1

SERVO1.data = MagicServoStateSerializer('deserialize',data);
SERVO1.hist(:,end+1) = [SERVO1.data.position; SERVO1.data.t];

if length(SERVO1.hist) > 10
  SERVO1.hist = SERVO1.hist(:,2:end);
end

SERVO1.cntr = SERVO1.cntr + 1;
tnow = GetUnixTime();

if (mod(SERVO1.cntr,40) == 0)
  dt = tnow - SERVO1.rateTime;
  fprintf('servo rate = %f\n',40/dt);
  SERVO1.rateTime = tnow;
end

dtServo1 = tnow - SERVO1.tLastArrival;

SERVO1.tLastArrival = tnow;
