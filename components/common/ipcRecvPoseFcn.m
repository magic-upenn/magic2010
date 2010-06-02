function ipcRecvPoseFcn(data,name)

global POSE

if ~isempty(data)
  POSE.data = MagicPoseSerializer('deserialize',data);
end