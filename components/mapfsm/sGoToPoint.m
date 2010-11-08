function ret = sGoToPoint(event, varargin);
global MPOSE PATH_DATA 

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
    fail = getPath();
    if fail
      disp('double fail');
      ret = 'done';
      return;
    end
    DATA.havePath = true;
    DATA.recovery_attempts = 0;
    DATA.recovering = false;
    sPath('entry');
  end
  ret = sPath('update');
  
  if strcmp(ret,'obstacle') || strcmp(ret,'timeout') || strcmp(ret,'stop') || strcmp(ret,'off path')
    DATA.havePath = false;
    ret = [];
  elseif strcmp(ret,'done')
    goal_dist = sqrt(sum(([MPOSE.x MPOSE.y]-PATH_DATA.goToPointGoal(end,1:2)).^2));
    if goal_dist > 1.0
      DATA.havePath = false;
      ret = [];
    end
  elseif strcmp(ret,'recovery')
    ret = [];
    if ~DATA.recovering
      DATA.recovering = true;
      DATA.recovery_attempts = DATA.recovery_attempts + 1;
    end
  else
    if DATA.recovering
      DATA.recovering = false;
      if DATA.recovery_attempts >= 3
        DATA.havePath = false;
      end
    end
  end
  
  %ret = 'gotGoToPointPath';
   
end


function fail = getPath()

global MPOSE PATH_DATA MAP AVOID_REGIONS

[planMap.size_x, planMap.size_y] = size(MAP);
planMap.resolution = resolution(MAP);
xmap = x(MAP);
planMap.UTM_x = xmap(1);
ymap = y(MAP);
planMap.UTM_y = ymap(1);
planMap.map = getdata(MAP, 'cost');

%add avoid regions
if ~isempty(AVOID_REGIONS.x)
  adjusted_regions.x = round((AVOID_REGIONS.x-planMap.UTM_x)/planMap.resolution);
  adjusted_regions.y = round((AVOID_REGIONS.y-planMap.UTM_y)/planMap.resolution);
  onMap = (adjusted_regions.x>0)&(adjusted_regions.x<=planMap.size_x)&(adjusted_regions.y>0)&(adjusted_regions.y<=planMap.size_y);
  planMap.map(sub2ind(size(planMap.map),adjusted_regions.x(onMap),adjusted_regions.y(onMap))) = 100;
end

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
  %trim the path
  [dummy, idx]=min(sum(([PATH_DATA.goToPointGoal(:,1)-MPOSE.x PATH_DATA.goToPointGoal(:,2)-MPOSE.y]).^2,2))
  PATH_DATA.goToPointGoal = PATH_DATA.goToPointGoal(idx:end,:);

  disp('sending explore path...');
  ret = lattice_planner_mex('explore_path',double(PATH_DATA.goToPointGoal))
  if ret > 0
    disp('we fail');
    fail = true;
    return;
  end
  disp('explore path sent!');
end

disp('planning...');
[path_x path_y path_yaw] = lattice_planner_mex('plan');
PATH_DATA.goToPointPath = [path_x path_y path_yaw];
disp('got plan!');
%size(PATH_DATA.goToPointPath)

ipcAPIPublish(GetMsgName('Planner_Path'), serialize(PATH_DATA.goToPointPath));

PATH_DATA.type = 1;
fail = false;

