function RascalmapfsmRecvPlannerPathFcn(data, name)

global PATH

if ~isempty(data)
  traj = deserialize(data);
  PATH.x = traj.x; % Column values
  PATH.y = traj.y; % Row values
  %[cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  %MP.sm = setEvent(MP.sm, 'gotGoToPointPath');
end

