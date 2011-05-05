function RascalmapfsmRecvPlannerPathFcn(data, name)

global PATH_DATA

if ~isempty(data)
  traj = deserialize(data);
  PATH_DATA.x = traj.x; % Column values
  PATH_DATA.y = traj.y; % Row values
  %[cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  %MP.sm = setEvent(MP.sm, 'gotGoToPointPath');
end

