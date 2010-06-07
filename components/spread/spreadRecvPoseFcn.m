function spreadRecvPoseFcn(msg)

global POSE

if ~isempty(msg),
  POSE = deserialize(msg);
  POSE.clock = clock;
end
