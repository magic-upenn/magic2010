function ret = sPath(event, varargin);

global MPOSE PATH MAP SPEED PATH_DATA
persistent DATA

timeout = 120.0;
ret = [];
switch event
 case 'entry'
  disp('sPath');

  DATA.t0 = gettime;
  DATA.tPredict = 0.1;
  DATA.speed = 0.3;

   PATH = PATH_DATA.explorePath(:,1:2);
   [dud1,idx,dud2] = unique(PATH,'rows','first');
   PATH = PATH(sort(idx),:);
 case 'exit'
  
 case 'update'
   PATH = PATH_DATA.explorePath(:,1:2);
   [dud1,idx,dud2] = unique(PATH,'rows','first');
   PATH = PATH(sort(idx),:);

   if isempty(PATH),
     disp('empty?');
     SetVelocity(0, 0);
     ret = 'stop';
     return;
   end

   if (gettime - DATA.t0 > timeout)
     disp('timeout?');
     ret = 'timeout';
   end

   dxEnd = PATH(end,1)-MPOSE.x;
   dyEnd = PATH(end,2)-MPOSE.y;
   dEnd = sqrt(dxEnd.^2+dyEnd.^2);

   [xNear, yNear, aNear] = pathClosestPoint(PATH, [MPOSE.x MPOSE.y]);
   dHeading = modAngle(aNear-MPOSE.heading);
   if (dEnd < 0.5) && abs(dHeading) < 30*pi/180,
     ret = 'done';
     disp('done?');
     return;
   end

   if abs(dHeading) > 45*pi/180,
     if (dHeading > 0),
       SetVelocity(0, SPEED.minTurn);
     else
       SetVelocity(0, -SPEED.minTurn);
     end
     return;
   end

   [turnPath, cost] = turnControl(PATH, MPOSE);

   % Check for obstacles ahead:
   xp = MPOSE.x + [.4:.1:5]*cos(MPOSE.heading);
   yp = MPOSE.y + [.4:.1:5]*sin(MPOSE.heading);
   dObstacle = pathObstacleDistance(xp, yp, MAP)

   if (dObstacle < .3),
     dxStart = PATH(1,1)-MPOSE.x;
     dyStart = PATH(1,2)-MPOSE.y;
     dStart = sqrt(dxStart.^2+dyStart.^2);
     if(dStart < 0.3)
       disp('recovery');
       SetVelocity(-0.4, 0);
       return;
     else
       disp('obstacle?');
       ret = 'obstacle';
     end
   end

   maxSpeed = min(.5*distToMaxSpeed(dObstacle), 1);
   if maxSpeed < DATA.speed,
     DATA.speed = maxSpeed;
   else
     DATA.speed = DATA.speed + .2*(maxSpeed-DATA.speed);
   end

   v = DATA.speed;
   w = turnPath*max(v, 0.1);
   disp(sprintf('drive: %.4f %.4f',v,w));
   SetVelocity(v, .4*w);

end
