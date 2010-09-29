function ret = sSpinRight(event, varargin);

global MPOSE
persistent DATA

timeout = 60.0;
ret = [];
switch event
 case 'entry'
  disp('sSpinRight');

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
   
   if (DATA.dheading < -2*pi)
     ret = 'done';
   end

   %{
   if (dt > 2.0 && -DATA.dheading/dt < 20*pi/180)
     DATA.w = DATA.w + .01;
     DATA.w = min(DATA.w, 1.0);
   end

   SetVelocity(0, -DATA.w);
   %}

   temp_ang = -45*pi/180 + heading;
   w = w_PID(heading, temp_ang, MPOSE.x, MPOSE.y, [MPOSE.x,MPOSE.y;cos(temp_ang),sin(temp_ang)]);
   w = sign(w)*min(abs(w), 3.0);
   SetVelocity(0,w);
   
end
