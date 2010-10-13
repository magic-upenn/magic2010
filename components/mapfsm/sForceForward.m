function ret = sForceBackup(event, varargin);

global MPOSE
persistent DATA

timeout = 0.5;
ret = [];
switch event
 case 'entry'
  disp('sForceForward');

  DATA.t0 = gettime;
  DATA.x0 = MPOSE.x;
  DATA.y0 = MPOSE.y;

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'
   SetVelocity(1.2, 0);

   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end
   
   dist = sqrt((MPOSE.x-DATA.x0).^2 + (MPOSE.y-DATA.y0).^2);
   if (dist > 0.3)
     ret = 'done';
   end
   
end
