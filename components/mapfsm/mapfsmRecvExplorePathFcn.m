function mapfsmRecvExplorePathFcn(data, name)
disp('got exploration goal');

global MP PATH_DATA

if ~isempty(data)
  traj = deserialize(data);
  %traj = MagicGP_TRAJECTORYSerializer('deserialize',data);
  %if(traj.num_traj_pts > 0)
  if(numel(traj) > 0)
    %traj_array = reshape(traj.traj_array, 6, [])';
    %PATH_DATA.explorePath = [traj_array(:,1) traj_array(:,2) traj_array(:,3)];
    PATH_DATA.explorePath = traj;
    PATH_DATA.newExplorePath = true;
  end

  %{
  traj = MagicMotionTrajSerializer('deserialize',data);
  PATH_DATA.explorePath = [cell2mat({traj.waypoints(:).x})',cell2mat({traj.waypoints(:).y})'];
  MP.sm = setEvent(MP.sm, 'gotExplorePath');
  %}
end

