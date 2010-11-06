function ret = sTrackHuman(event, varargin);

global MPOSE PATH
global TRACKS OOI_DYNAMIC LOOK_ANGLE
persistent DATA

timeout = 60.0;
ret = [];
switch event
 case 'entry'
  disp('sTrackHuman');

  DATA.t0 = gettime;
  DATA.minDistThreshold = 1.0;
  DATA.maxDistThreshold = 6.0;
  DATA.distRate = 2.0;
  DATA.kp = 3;
  DATA.wmax = 1.0;
  DATA.lastTrack = gettime;
  DATA.trackAngleThresh = 75*pi/180;

  if ~isempty(OOI_DYNAMIC),
    DATA.x = OOI_DYNAMIC(1);
    DATA.y = OOI_DYNAMIC(2);
  else
    disp('No initial OOI position given, tracking nearest human');
    DATA.x = MPOSE.x;
    DATA.y = MPOSE.y;
  end

%{
  DATA.init = 0;

  if isempty(TRACKS) || isempty(TRACKS.xs),
    disp('Track is not initialized!');
    DATA.x = cos(LOOK_ANGLE)+MPOSE.x;
    DATA.y = sin(LOOK_ANGLE)+MPOSE.y;
    return
  end

  ax = MPOSE.x;
  ay = MPOSE.y;
  bx = ax+30*cos(LOOK_ANGLE);
  by = ay+30*sin(LOOK_ANGLE);
  cx = TRACKS.xs;
  cy = TRACKS.ys;

  r_num = (cx-ax)*(bx-ax) + (cy-ay)*(by-ay);
  r_den = (bx-ax)*(bx-ax) + (by-ay)*(by-ay);
  r = r_num./r_den;

  isNearLine = (r>=0)&(r<=1);

  dist = zeros(size(r));

  s = ((ay-cy)*(bx-ax)-(ax-cx)*(by-ay))./r_den;
  dist(isNearLine) = abs(s(isNearLine)).*sqrt(r_den(isNearLine));

  distEnd = (cx-bx)*(cx-bx) + (cy-by)*(cy-by);
  isNearEnd = (~isNearLine);
  dist(isNearEnd) = sqrt(distEnd(isNearEnd));

  [minVal, minIdx] = min(dist);

  DATA.x = TRACKS.xs(minIdx);
  DATA.y = TRACKS.ys(minIdx);
  DATA.init = 1;
%}

  sLook('entry');

 case 'exit'
   SetVelocity(0,0);  
   sLook('exit');
  
 case 'update'

   %if (gettime - DATA.t0 > timeout)
     %ret = 'timeout';
   %end

   %if ~DATA.init
     %sTrackHuman('entry');
   %end

   tempTracks = [];
   if ~isempty(TRACKS) && ~isempty(TRACKS.xs) %&& DATA.init,
     angles = modAngle(atan2((TRACKS.ys-MPOSE.y),(TRACKS.xs-MPOSE.x))-MPOSE.yaw);
     idx = abs(angles)<DATA.trackAngleThresh;
     
     tempTracks.xs = TRACKS.xs(idx);
     tempTracks.ys = TRACKS.ys(idx);
     angles = modAngle(atan2((tempTracks.ys-MPOSE.y),(tempTracks.xs-MPOSE.x))-MPOSE.yaw)*180/pi;
   end

   if ~isempty(tempTracks) && ~isempty(tempTracks.xs) %&& DATA.init,
     dx = tempTracks.xs - DATA.x;
     dy = tempTracks.ys - DATA.y;
     dist = sqrt(dx.^2 + dy.^2);
     [dmin, imin] = min(dist);

      distThresh = min(DATA.minDistThreshold + DATA.distRate*(gettime-DATA.lastTrack),DATA.maxDistThreshold);

     if (dmin < distThresh),
       DATA.x = DATA.x+.25*(tempTracks.xs(imin)-DATA.x);
       DATA.y = DATA.y+.25*(tempTracks.ys(imin)-DATA.y);
       DATA.lastTrack = gettime;
     end
   end


   LOOK_ANGLE = atan2(DATA.y-MPOSE.y, DATA.x-MPOSE.x);
   sLook('update');

   %{
   dAngle = atan2(DATA.y-MPOSE.y, DATA.x-MPOSE.x) - MPOSE.heading;
   w = DATA.kp*dAngle;
   if (abs(w) > DATA.wmax)
     w = sign(w)*DATA.wmax;
   end
   SetVelocity(0, w);
   %}
   
end
