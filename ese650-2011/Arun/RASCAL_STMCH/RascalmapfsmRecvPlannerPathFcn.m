function RascalmapfsmRecvPlannerPathFcn(data, name)

global PATH

if ~isempty(data)
  traj = deserialize(data);
  PATH = zeros(numel(traj.x),2);
  
  PATH(:,1) = fliplr(traj.x); % Column values
  PATH(:,2) = fliplr(traj.y); % Row values
  %[cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  %MP.sm = setEvent(MP.sm, 'gotGoToPointPath');
end

