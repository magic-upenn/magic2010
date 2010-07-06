function mapfsmRecvPlannerPathFcn(data, name)

global MP PATH

if ~isempty(data)
  traj = MagicMotionTrajSerializer('deserialize',data);
  PATH = [cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  MP.sm = setEvent(MP.sm, 'gotPath');
end

