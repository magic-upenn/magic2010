function ret = sSpinLeft(event, varargin);

global MPOSE
persistent DATA

timeout = 15.0;
ret = [];
switch event
 case 'entry'
  disp('sSpinLeft');

  DATA.t0 = gettime;
  DATA.heading0 = MPOSE.heading;
  DATA.dheading = 0;

 case 'exit'
   SetVelocity(0,0);  
  
 case 'update'
   SetVelocity(0, .3);

   if (gettime - DATA.t0 > timeout)
    ret = 'timeout';
   end

   heading = MPOSE.heading;
   DATA.dheading = DATA.dheading + (heading - DATA.heading0);
   DATA.heading0 = heading;

if (DATA.dheading > 2*pi)
  ret = 'done';
end

end
