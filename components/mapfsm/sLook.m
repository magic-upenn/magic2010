function ret = sLook(event, varargin);

global MPOSE
persistent DATA

timeout = 5.0;
ret = [];
switch event
 case 'entry'
  disp('sLook');

  DATA.t0 = gettime;
  %{
  plannerState.shouldRun = 1;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));

  goal.id=0;
  goal.num_traj_pts = 1;
  goal.traj_dim = 3;
  goal.traj_array = [PATH(1) PATH(2) atan2(PATH(2)-MPOSE.y,PATH(1)-MPOSE.x)];
  ipcAPIPublishVC(GetMsgName('Waypoints'), ...
                  MagicGP_TRAJECTORYSerializer('serialize', plannerState));
  %}

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
