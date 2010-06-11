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
