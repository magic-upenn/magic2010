function mapfsmRecvLookMsgFcn(data, name)
global LOOK_ANGLE MP

if ~isempty(data)
  disp('got look msg');
  msg = deserialize(data);
  
  switch msg.type
  case 'done'
    MP.sm = setEvent(MP.sm, 'done_looking');
  case 'look'
    LOOK_ANGLE = msg.theta;
    MP.sm = setEvent(MP.sm, 'look');
  case 'track'
    LOOK_ANGLE = msg.theta;
    MP.sm = setEvent(MP.sm, 'track');
  end
end
