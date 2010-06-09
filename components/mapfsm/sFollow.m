function ret = sPath(event, varargin);

global MPOSE PATH
persistent DATA

timeout = 120.0;
ret = [];
switch event
 case 'entry'
  disp('sPath');

  DATA.t0 = gettime;
  DATA.tPredict = 0.1;
  DATA.speed = 0.5;

 case 'exit'
  
 case 'update'
   if isempty(PATH),
     SetVelocity(0, 0);
     ret = 'stop';
     return;
   end

   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end

   dxEnd = PATH(end,1)-MPOSE.x;
   dyEnd = PATH(end,2)-MPOSE.y;
   dEnd = sqrt(dxEnd.^2+dyEnd.^2);

   [xNear, yNear, aNear] = pathClosestPoint(PATH, [MPOSE.x MPOSE.y]);
   dHeading = modAngle(aNear-MPOSE.heading);
   if (dEnd < 0.5) && abs(dHeading) < 30*pi/180,
     ret = 'done';
     return;
   end

   if abs(dHeading) > 45*pi/180,
     if (dHeading > 0),
       SetVelocity(0, .4);
     else
       SetVelocity(0, -.4);
     end
     return;
   end

   [turnPath, cost] = turnControl(PATH, MPOSE);

   maxSpeed = distToMaxSpeed(dEnd);

   v = min(DATA.speed, maxSpeed);
   w = turnPath*max(v, 0.1);
   disp(sprintf('drive: %.4f %.4f',v,w));
   SetVelocity(v, .5*w);

end
