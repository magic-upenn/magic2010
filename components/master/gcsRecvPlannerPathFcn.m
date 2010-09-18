function gcsRecvPlannerPathFcn(data, name)

global RPATH GPATH

if isempty(data)
  return;
end

id = GetIdFromName(name);

fprintf('got path from robot %d\n',id);

%traj = MagicMotionTrajSerializer('deserialize',data);
%RPATH{id}.x = cell2mat({traj.waypoints(:).x})';
%RPATH{id}.y = cell2mat({traj.waypoints(:).y})';
traj = deserialize(data);
RPATH{id}.x = traj(:,1);
RPATH{id}.y = traj(:,2);

%{
GPATH{id} = RPATH{id};
for i=1:size(GPATH{id},1)
  [GPATH{id}.x(i), GPATH{id}.y(i), dummy] = rpos_to_gpos(id, RPATH{id}.x(i), RPATH{id}.y(i));
end
%}
[GPATH{id}.x, GPATH{id}.y, dummy] = rpos_to_gpos(id, RPATH{id}.x, RPATH{id}.y);

