function RascalmapfsmRecvPoseFcn(data, name)

global POSE

if ~isempty(data)
  POSE = deserialize(data);
  %POSE.heading = POSE.yaw;
end
