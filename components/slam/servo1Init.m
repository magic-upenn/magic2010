function servo1Init
global SERVO1

if isempty(SERVO1) || ~isfield(SERVO1,'initialized') ||(SERVO1.initialized ~= 1)
  SERVO1.msgName = [GetRobotName '/Servo1'];
  SERVO1.data    = [];
  SERVO1.timeout = 0.1;
  SERVO1.hist    = [];
  SERVO1.tLastArrival = [];
  SERVO1.cntr    = 0;
  SERVO1.rateTime = GetUnixTime();
 
  ipcInit;
  ipcAPIDefine(SERVO1.msgName,MagicServoStateSerializer('getFormat'));
  
  SERVO1.initialized = 1;
  disp('Servo1 initialized');
end
  
