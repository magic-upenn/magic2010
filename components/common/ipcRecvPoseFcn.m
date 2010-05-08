function ipcRecvPoseFcn(msg)

global POSE

if ~isempty(msg)
  POSE.data = MagicPoseSerializer('deserialize',msg);
end