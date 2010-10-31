function encodersInit
global ENCODERS

if isempty(ENCODERS) || (ENCODERS.initialized ~= 1)
  ENCODERS.msgName          = [GetRobotName '/Encoders'];
  ENCODERS.counts           = [];
  ENCODERS.acounts          = zeros(4,1);
  ENCODERS.tLastReset       = [];
  ENCODERS.tLast            = [];
  ENCODERS.wheelCirc        = 10 * 0.0254 * pi;  %meters
  ENCODERS.ticsPerRev       = 360.0;
  ENCODERS.metersPerTic     = ENCODERS.wheelCirc / ENCODERS.ticsPerRev;
  ENCODERS.robotRadius      = 0.22;
  ENCODERS.robotRadiusFudge = 2;
  ENCODERS.ticsPerMeter     = 1/ENCODERS.metersPerTic;
  ENCODERS.cntr             = 0;
  
  ipcInit;
  ipcAPIDefine(ENCODERS.msgName,MagicEncoderCountsSerializer('getFormat'));
  
  ENCODERS.initialized  = 1;
  disp('Encoders initialized');
end
