function RascalmapfsmRecvGoalPointFcn(data, name)

global MP GOAL POSE

if ~isempty(data)
  goal = deserialize(data);
  GOAL = [goal(:,1) goal(:,2) atan2(goal(2)-POSE.y,goal(1)-POSE.x)*ones(size(goal,1),1)];
  MP.sm = setEvent(MP.sm, 'goToPoint');
end
