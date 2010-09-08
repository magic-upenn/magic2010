function ret = sGoToPoint(event, varargin);

global MPOSE PATH_DATA MAP
persistent DATA

timeout = 5.0;
ret = [];
switch event
 case 'entry'
  disp('sGoToPoint');

  DATA.t0 = gettime;
  
  %{
  PATH_DATA.type = 1;
  plannerState.shouldRun = 1;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));

  goal.id=0;
  goal.num_traj_pts = 1;
  goal.traj_dim = 3;
  goal.traj_array = single([PATH_DATA.goToPointGoal(1) PATH_DATA.goToPointGoal(2) atan2(PATH_DATA.goToPointGoal(2)-MPOSE.y,PATH_DATA.goToPointGoal(1)-MPOSE.x)]);
  ipcAPIPublishVC(GetMsgName('Waypoints'), ...
                  MagicGP_TRAJECTORYSerializer('serialize', goal));
  %}

  [planMap.size_x, planMap.size_y] = size(MAP);
  planMap.resolution = resolution(MAP);
  xmap = x(MAP);
  planMap.UTM_x = xmap(1);
  ymap = y(MAP);
  planMap.UTM_y = ymap(1);
  planMap.map = getdata(MAP, 'cost');
  disp('sending map...');
  lattice_planner_mex('map',[planMap.size_x planMap.size_y planMap.resolution planMap.UTM_x planMap.UTM_y], planMap.map);
  disp('map sent!');
  disp('sending pose...');
  lattice_planner_mex('pose',[MPOSE.x MPOSE.y MPOSE.heading]);
  disp('pose sent!');
  disp('sending goal...');
  lattice_planner_mex('goal',[PATH_DATA.goToPointGoal(1) PATH_DATA.goToPointGoal(2) atan2(PATH_DATA.goToPointGoal(2)-MPOSE.y,PATH_DATA.goToPointGoal(1)-MPOSE.x)]);
  disp('goal sent!');
  disp('planning...');
  [path_x path_y path_yaw] = lattice_planner_mex('plan');
  PATH_DATA.goToPointPath = [path_x path_y path_yaw];
  disp('got plan!');
  size(PATH_DATA.goToPointPath)
  PATH_DATA.type = 1;
  ret = 'gotGoToPointPath';

 case 'exit'
  disp('done getting path');
  %{
  plannerState.shouldRun = 0;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));
  %}
  
 case 'update'
   if (gettime - DATA.t0 > timeout)
     ret = 'timeout';
   end
   ret = 'gotGoToPointPath';
end
