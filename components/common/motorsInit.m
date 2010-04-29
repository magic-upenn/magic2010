function motorsInit
global MOTORS ENCODERS

if isempty(MOTORS) || (MOTORS.initialized ~= 1)
  ipcInit;
  encodersInit;
  MOTORS.msgName      = [GetRobotName '/VelocityCmd'];
  MOTORS.vscale       = 1;
  MOTORS.wscale       = 1;
  ipcAPIDefine(MOTORS.msgName,MagicVelocityCmdSerializer('getFormat'));
  MOTORS.initialized  = 1;
  disp('Motors initialized');
end