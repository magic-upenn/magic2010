function ret = sWait(event, varargin)

global GOAL
%persistent tx;
ret = [];
switch event
 case 'entry'
    disp('sWait');
    SetVelocity(0,0);

    %GOAL = [];
    %tx = gettime;
 %{
 plannerState.shouldRun = 0;
 ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                 MagicGP_SET_STATESerializer('serialize', plannerState));
 %}

 case 'exit'
    
 case 'update'
    if ~isempty(GOAL),
    %if(gettime - tx > 2)
        disp('Scanning...');
        ret = 'scan';
    end

end
