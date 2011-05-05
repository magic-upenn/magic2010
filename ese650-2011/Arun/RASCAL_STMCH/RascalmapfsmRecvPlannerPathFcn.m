function mapfsmRecvPlannerPathFcn(data, name)

global MP PATH_DATA

if ~isempty(data)
  traj = MagicMotionTrajSerializer('deserialize',data);
  PATH_DATA.goToPointPath = [cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  MP.sm = setEvent(MP.sm, 'gotGoToPointPath');
end

