function ret = sWait_R(event, varargin)

global GOAL
global PREV_GOAL;
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
    if ~isempty(GOAL) && ~isequal(PREV_GOAL,GOAL),
    %if(gettime - tx > 2)
        PREV_GOAL = GOAL;
        %GOAL = [];
        disp('Got a goal point...');
        ret = 'Scan';
    end
end
