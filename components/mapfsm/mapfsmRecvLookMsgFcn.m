function mapfsmRecvLookMsgFcn(data, name)
global LOOK_ANGLE MP MPOSE OOI_DYNAMIC BODY_FACE TILT_ANGLE

if ~isempty(data)
  disp('got look msg');
  msg = deserialize(data);
  
  switch msg.type
  case 'done'
    MP.sm = setEvent(MP.sm, 'done_looking');
  case 'look'
    LOOK_ANGLE = msg.theta;
    TILT_ANGLE = msg.phi;
    BODY_FACE = false;
    MP.sm = setEvent(MP.sm, 'look');
  case 'face'
    LOOK_ANGLE = msg.theta;
    BODY_FACE = true;
    MP.sm = setEvent(MP.sm, 'look');
  case 'track'
    OOI_DYNAMIC(1) = MPOSE.x + msg.distance*cos(msg.theta);
    OOI_DYNAMIC(2) = MPOSE.y + msg.distance*sin(msg.theta);
    MP.sm = setEvent(MP.sm, 'track');
  end
end
