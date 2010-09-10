function ret = sExplore(event, varargin);

global MPOSE PATH_DATA
persistent DATA

ret = [];
switch event
 case 'entry'
  disp('sExplore');

  %{
  PATH_DATA.type = 2;
  plannerState.shouldRun = 2;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));
  %}

 case 'exit'
   %{
   plannerState.shouldRun = 0;
   ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                   MagicGP_SET_STATESerializer('serialize', plannerState));
   %}
  
 case 'update'

   if PATH_DATA.newExplorePath
      PATH_DATA.newExplorePath = false;
      PATH_DATA.goToPointGoal(1) = PATH_DATA.explorePath(end,1);
      PATH_DATA.goToPointGoal(2) = PATH_DATA.explorePath(end,2);
      sGoToPoint('entry');
   end
   
   switch DATA.waitForGoal
     case 0
       ret = sGoToPoint('update');
       if ret=='done'
         DATA.waitForGoal = 1;
       end
     case 1
       sSpinLeft('entry');
       DATA.waitForGoal = 2;
     case 2
       ret = sSpinLeft('update');
       if ret=='done' || ret=='timeout'
         DATA.waitForGoal = 3;
       end
     case 3
       sSpinLeft('exit');
   end

   ret = [];

end
