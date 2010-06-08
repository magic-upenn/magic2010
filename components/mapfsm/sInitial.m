function ret = sInitial(event, varargin);

global MPOSE

ret = [];
switch event
 case 'entry'
  disp('sInitial: Waiting for initial pose');

 case 'exit'
    
 case 'update'
  if ~isempty(MPOSE),
    ret = 'pose';
  end

end
