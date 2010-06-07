function servo1Init
global SERVO1

if isempty(SERVO1) || ~isfield(SERVO1,'initialized') ||(SERVO1.initialized ~= 1)
  SERVO1.msgName = [GetRobotName '/Servo1'];
  SERVO1.data    = [];
  SERVO1.offsetx = 0.165;
  SERVO1.offsety = 0;
  SERVO1.offsetz = 0.40;
  SERVO1.offsetYaw = 0/180*pi;  %TODO: load this from config file
  
  ipcInit;
  ipcAPIDefine(SERVO1.msgName,MagicServoStateSerializer('getFormat'));
  
  SERVO1.initialized = 1;
  disp('Servo1 initialized');
end
  