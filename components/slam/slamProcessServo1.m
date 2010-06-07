%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Servo1 message handler 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessServo1(data,name)
global SERVO1

SERVO1.data = MagicServoStateSerializer('deserialize',data);
