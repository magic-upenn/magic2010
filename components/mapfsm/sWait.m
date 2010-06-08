function ret = sWait(event, varargin);

global MPOSE DRIVE

ret = [];
switch event
 case 'entry'
 disp('sWait');
DRIVE = [];

 case 'exit'
    
 case 'update'
  if ~isempty(DRIVE),
    ret = 'start';
  end

end
