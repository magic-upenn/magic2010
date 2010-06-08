function ret = sSpinLeft(event, varargin);

timeout = 15.0;
ret = [];
switch event
 case 'entry'
 disp('sSpinLeft');

 case 'exit'
    
 case 'update'
  if ~isempty(POSE),
    ret = 'pose';
  end

end
