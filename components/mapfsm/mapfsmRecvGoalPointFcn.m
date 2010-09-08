function mapfsmRecvGoalPointFcn(data, name)

global MP PATH_DATA

if ~isempty(data)
  PATH_DATA.goToPointGoal = deserialize(data);
  MP.sm = setEvent(MP.sm, 'goToPoint');
end
