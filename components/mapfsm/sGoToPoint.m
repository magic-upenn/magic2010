function ret = sGoToPoint(event, varargin);

persistent DATA

ret = [];
switch event
 case 'entry'
  disp('sGoToPoint');

  DATA.havePath = false;
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


 case 'exit'
  %{
  plannerState.shouldRun = 0;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));
  %}
  
 case 'update'
  if ~DATA.havePath
    getPath();
    DATA.havePath = true;
    sPath('entry');
  end
  ret = sPath('update');
  
  if strcmp(ret,'obstacle') || strcmp(ret,'timeout') || strcmp(ret,'stop')
    DATA.havePath = false;
    ret = [];
  elseif strcmp(ret,'recovery')
    ret = [];
  end
  
  %ret = 'gotGoToPointPath';
   
end


function getPath()

global MPOSE PATH_DATA MAP

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

if(size(PATH_DATA.goToPointGoal,1) == 1)
  disp('sending goal...');
  lattice_planner_mex('goal',PATH_DATA.goToPointGoal);
  disp('goal sent!');
else
  disp('sending explore path...');
  lattice_planner_mex('explore_path',PATH_DATA.goToPointGoal);
  disp('explore path sent!');
end

disp('planning...');
[path_x path_y path_yaw] = lattice_planner_mex('plan');
PATH_DATA.goToPointPath = [path_x path_y path_yaw];
disp('got plan!');
size(PATH_DATA.goToPointPath)
PATH_DATA.type = 1;

