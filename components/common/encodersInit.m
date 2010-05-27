function encodersInit
global ENCODERS

if isempty(ENCODERS) || (ENCODERS.initialized ~= 1)
  ENCODERS.msgName          = [GetRobotName '/Encoders'];
  ENCODERS.counts           = [];
  ENCODERS.acounts          = zeros(4,1);
  ENCODERS.tLastReset       = [];
  ENCODERS.tLast            = [];
  ENCODERS.wheelCirc        = 6.5 * 0.0254 * pi;  %meters
  ENCODERS.metersPerTic     = ENCODERS.wheelCirc / 180.0;
  ENCODERS.robotRadius      = 0.22;
  ENCODERS.robotRadiusFudge = 2;
  ENCODERS.ticsPerMeter     = 1/ENCODERS.metersPerTic;
  ENCODERS.cntr             = 0;
  
  ipcInit;
  ipcAPIDefine(ENCODERS.msgName,MagicEncoderCountsSerializer('getFormat'));
  
  
  ENCODERS.initialized  = 1;
  disp('Encoders initialized');
end