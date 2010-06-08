function ret = sFreeze(event, varargin);

global POSE

ret = [];
switch event
 case 'entry'
  disp('sFreeze!');

 case 'exit'
    
 case 'update'
   SetVelocity(0,0);

end
