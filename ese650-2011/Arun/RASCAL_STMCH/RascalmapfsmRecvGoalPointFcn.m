function RascalmapfsmRecvGoalPointFcn(data, name)

global MP GOAL POSE LIDAR K_LIDAR QUEUELASER

if ~isempty(data)
  goal = deserialize(data);
  GOAL = [goal(:,1) goal(:,2) atan2(goal(2)-POSE.y,goal(1)-POSE.x)*ones(size(goal,1),1)];
  MP.sm = setEvent(MP.sm, 'goToPoint');
  LIDAR = {};
  K_LIDAR = []; 
  QUEUELASER = false;
  %setServotoPoint;
end
