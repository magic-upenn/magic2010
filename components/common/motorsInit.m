function motorsInit
global MOTORS

if isempty(MOTORS) || (MOTORS.initialized ~= 1)
  ipcInit;
  MOTORS.msgName      = [GetRobotName '/VelocityCmd'];
  MOTORS.wheelCirc    =  6.5 * 0.0254 * pi;  %meters
  MOTORS.metersPerTic = MOTORS.wheelCirc / 180.0;
  MOTORS.roborRadius  = 0.22;
  MOTORS.ticsPerMeter = 1/MOTORS.metersPerTic;
  MOTORS.vscale       = 127;
  MOTORS.wscale       = 127;
  ipcAPIDefine(MOTORS.msgName,MagicVelocityCmdSerializer('getFormat'));
  MOTORS.initialized  = 1;
end