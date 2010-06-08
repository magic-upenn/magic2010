function mapfsmRecvPoseFcn(data, name)

global MPOSE

if ~isempty(data)
  MPOSE = MagicPoseSerializer('deserialize', data);
  MPOSE.heading = MPOSE.yaw;
end
