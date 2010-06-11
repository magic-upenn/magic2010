function ret = sTrackHuman(event, varargin);

global MPOSE PATH
global TRACKS OOI_DYNAMIC
persistent DATA

timeout = 60.0;
ret = [];
switch event
 case 'entry'
  disp('sTrackHuman');

  DATA.t0 = gettime;
  DATA.distThreshold = 3.0;
  DATA.kp = 3;
  DATA.wmax = 1.0;

  if ~isempty(OOI_DYNAMIC),
    DATA.x = OOI_DYNAMIC(1);
    DATA.y = OOI_DYNAMIC(2);
  else
    disp('No initial OOI position given, tracking nearest human');
    DATA.x = MPOSE.x;
    DATA.y = MPOSE.y;
  end

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'

   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end

   if ~isempty(TRACKS) && ~isempty(TRACKS.xs),
     dx = TRACKS.xs - DATA.x;
     dy = TRACKS.ys - DATA.y;
     dist = sqrt(dx.^2 + dy.^2);
     [dmin, imin] = min(dist);
     if (dmin < DATA.distThreshold),
       DATA.x = DATA.x+.25*(TRACKS.xs(imin)-DATA.x);
       DATA.y = DATA.y+.25*(TRACKS.ys(imin)-DATA.y);
     end
   end

   dAngle = atan2(DATA.y-MPOSE.y, DATA.x-MPOSE.x) - MPOSE.heading;
   w = DATA.kp*dAngle;
   if (abs(w) > DATA.wmax)
     w = sign(w)*DATA.wmax;
   end
   SetVelocity(0, w);
   
end
