function ret = sForceSpinRight(event, varargin);

global MPOSE
persistent DATA

timeout = 0.5;
ret = [];
switch event
 case 'entry'
  disp('sForceSpinRight');

  DATA.t0 = gettime;
  DATA.heading0 = MPOSE.heading;
  DATA.dheading = 0;
  DATA.w = .4;

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'
   dt = gettime - DATA.t0;
   if (dt > timeout)
     ret = 'timeout';
   end
   
   heading = MPOSE.heading;
   DATA.dheading = DATA.dheading + (heading - DATA.heading0);
   DATA.heading0 = heading;
   
   if (DATA.dheading < -pi/2)
     ret = 'done';
   end

   SetVelocity(0, -3.0);

end
