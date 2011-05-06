function ret = sFollow(event, varargin)

global POSE PATH SPEED
persistent DATA

timeout = 10.0;
ret = [];
switch event
 case 'entry'
  disp('sPath');

  DATA.t0 = gettime;
  DATA.tPredict = 0.1;
  DATA.speed = 0.5;
  DATA.x = POSE.x;
  DATA.y = POSE.y;

 case 'exit'
  
 case 'update'
   if isempty(PATH),
     SetVelocity(0, 0);
     ret = 'Stop';
     return;
   end

   dst = sqrt((POSE.x - DATA.x).^2 + (POSE.y-DATA.y).^2);
   if(dst > 2)
     SetVelocity(0, 0);
     ret = 'Dist';
     return;
   end
   if (gettime - DATA.t0 > timeout)
    ret = 'Timeout';
   end

   dxEnd = PATH(end,1)-POSE.x;
   dyEnd = PATH(end,2)-POSE.y;
   dEnd = sqrt(dxEnd.^2+dyEnd.^2);

   [xNear, yNear, aNear] = pathClosestPoint(PATH, [POSE.x POSE.y]);
   dHeading = modAngle(aNear-POSE.yaw);
   if (dEnd < 0.5) && abs(dHeading) < 30*pi/180,
     ret = 'Done';
     return;
   end

   if abs(dHeading) > 45*pi/180,
     if (dHeading > 0),
       SetVelocity(0, 0.5);%SPEED.minTurn);
     else
       SetVelocity(0, -0.5);%-SPEED.minTurn);
     end
     return;
   end

   [turnPath, cost] = turnControl(PATH, POSE);

   maxSpeed = distToMaxSpeed(dEnd);

   v = min(DATA.speed, maxSpeed);
   w = turnPath*max(v, 0.1);
   disp(sprintf('drive: %.4f %.4f',v,w));
   SetVelocity(v, .4*w);

end
