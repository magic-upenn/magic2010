function ret = sTrackHuman(event, varargin);

global MPOSE PATH
persistent DATA

timeout = 10.0;
ret = [];
switch event
 case 'entry'
  disp('sTrackHuman');

  DATA.t0 = gettime;

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'

   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end

   dAngle = atan2(PATH(2)-MPOSE.y,PATH(1)-MPOSE.x) - MPOSE.heading;
   w = kp*dAngle;
   if(abs(w)<0.4)
     w = sign(w)*0.4;
   end
   SetVelocity(0, w);
   
   if (dAngle < 20*pi/180)
     ret = 'done';
   end
   
end
