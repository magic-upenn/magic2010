function ret = sInitial(event, varargin);

global POSE

ret = [];
switch event
 case 'entry'
  disp('sInitial: Waiting for initial pose');

 case 'exit'
    
 case 'update'
  if ~isempty(POSE),
    ret = 'pose';
  end

end
