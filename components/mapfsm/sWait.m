function ret = sWait(event, varargin);

global DRIVE

ret = [];
switch event
 case 'entry'
  disp('sWait: Waiting for initial pose');

 case 'exit'
    
 case 'update'
  if ~isempty(POSE),
    ret = 'pose';
  end

end
