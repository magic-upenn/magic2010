function ret = sWait(event, varargin);

global MPOSE DRIVE

ret = [];
switch event
 case 'entry'
 disp('sWait');
 DRIVE = [];

 %{
 plannerState.shouldRun = 0;
 ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                 MagicGP_SET_STATESerializer('serialize', plannerState));
 %}

 case 'exit'
    
 case 'update'
  if ~isempty(DRIVE),
    ret = 'start';
  end

end
