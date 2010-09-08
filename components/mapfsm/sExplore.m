function ret = sExplore(event, varargin);

global MPOSE
persistent DATA

timeout = 15.0;
ret = [];
switch event
 case 'entry'
  disp('sExplore');

  DATA.t0 = gettime;
  
  PATH_DATA.type = 2;
  plannerState.shouldRun = 2;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));

 case 'exit'
   %{
   plannerState.shouldRun = 0;
   ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                   MagicGP_SET_STATESerializer('serialize', plannerState));
                   %}
  
 case 'update'
   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end
end
