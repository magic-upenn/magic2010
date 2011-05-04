function RascalmapfsmRecvPoseFcn(data, name)

global POSE

if ~isempty(data)
  POSE = MagicPoseSerializer('deserialize', data);
  %POSE.heading = POSE.yaw;
end
