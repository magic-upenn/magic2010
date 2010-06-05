%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoder message handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessEncoders(data,name)
global ENCODERS SLAM IMU

if isempty(IMU)
    return
end

if ~isempty(data)
  ENCODERS.counts  = MagicEncoderCountsSerializer('deserialize',data);
  ENCODERS.cntr    = ENCODERS.cntr + 1;
  
  if isempty(ENCODERS.tLastReset)
    ENCODERS.tLastReset = ENCODERS.counts.t;
    ENCODERS.tLast = ENCODERS.counts.t;
    return;
  end
  
  counts = ENCODERS.counts;
  ENCODERS.acounts = ENCODERS.acounts + [counts.fr;counts.fl;counts.rr;counts.rl];

  %dt for velocity calculation
  dtv = counts.t-ENCODERS.tLastReset;
  if (dtv > 0.1)
    ENCODERS.wheelVels = ENCODERS.acounts / dtv * ENCODERS.metersPerTic;
    ENCODERS.acounts = ENCODERS.acounts*0;
    ENCODERS.tLastReset = counts.t;
  end
  
  
  %get the mean travelled distance for left and right sides
  rc = mean([ENCODERS.counts.rr ENCODERS.counts.fr]) * ENCODERS.metersPerTic;
  lc = mean([ENCODERS.counts.rl ENCODERS.counts.fl]) * ENCODERS.metersPerTic;
  
  %rc = ENCODERS.counts.rr * ENCODERS.metersPerTic;
  %lc = ENCODERS.counts.rl * ENCODERS.metersPerTic;
  
  
  vdt = mean([rc,lc]);
  
  %the fudge factor scales the angular change due to slippage
  %TODO: this will also affect vdt!!
  wdt = (rc - lc)/(2*ENCODERS.robotRadius*ENCODERS.robotRadiusFudge);
  %dt = counts.t - ENCODERS.tLast;
  
  xPrev   = SLAM.x;
  yPrev   = SLAM.y;
  yawPrev = SLAM.yaw;
  
  %calculate the change in position
  if (abs(wdt) > 0.001)
    dx   = -vdt/wdt*sin(yawPrev) + vdt/wdt*sin(yawPrev+wdt);
    dy   =  vdt/wdt*cos(yawPrev) - vdt/wdt*cos(yawPrev+wdt);
    dyaw =  wdt;
  else
    dx   =  vdt*cos(yawPrev);
    dy   =  vdt*sin(yawPrev);
    dyaw =  wdt;
  end
  
  
  %this does not seem to do anything...
  %the idea is to project the displacement onto the 2D plane, given pitch
  %and roll
  dTrans       = rotz(SLAM.yaw)*roty(IMU.data.pitch)*rotx(IMU.data.roll)*rotz(SLAM.yaw)'*[dx;dy;0;1]; 
  
  SLAM.xOdom   = xPrev   + dTrans(1);
  SLAM.yOdom   = yPrev   + dTrans(2);
  SLAM.yawOdom = yawPrev + dyaw;
  
end