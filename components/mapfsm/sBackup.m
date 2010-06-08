function ret = sBackup(event, varargin);

global MPOSE
persistent DATA

timeout = 4.0;
ret = [];
switch event
 case 'entry'
  disp('sBackup');

  DATA.t0 = gettime;
  DATA.x0 = MPOSE.x;
  DATA.y0 = MPOSE.y;

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'
   SetVelocity(-.4, 0);

   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end
   
   dist = sqrt((MPOSE.x-DATA.x0).^2 + (MPOSE.y-DATA.y0).^2);
   if (dist > 1.0)
     ret = 'done';
   end
   
end
