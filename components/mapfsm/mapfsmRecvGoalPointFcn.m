function mapfsmRecvGoalPointFcn(data, name)

global MP PATH

if ~isempty(data)
  PATH = deserialize(data);
  MP.sm = setEvent(MP.sm, 'goToPoint');
end
