function motorsInit
global MOTORS ENCODERS

if isempty(MOTORS) || (MOTORS.initialized ~= 1)
  ipcInit;
  encodersInit;
  MOTORS.msgName      = [GetRobotName '/VelocityCmd'];
  ipcAPIDefine(MOTORS.msgName,MagicVelocityCmdSerializer('getFormat'));
  MOTORS.initialized  = 1;
  disp('Motors initialized');
end