function poseInit
global POSE

if isempty(POSE) || ~isfield(POSE,'initialized') ||(POSE.initialized ~= 1)
  POSE.msgName = [GetRobotName '/Pose'];
  POSE.pose = [];
  POSE.xInit   = 0;
  POSE.yInit   = 0;
  POSE.yawInit = 0;
  POSE.data.x       = 0;
  POSE.data.y       = 0;
  POSE.data.z       = 0;
  POSE.data.roll    = 0;
  POSE.data.pitch   = 0;
  POSE.data.yaw     = 0;
  
  ipcInit;
  ipcAPIDefine(POSE.msgName,MagicPoseSerializer('getFormat'));
  POSE.initialized  = 1;
  disp('Pose initialized');
end