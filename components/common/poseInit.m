function poseInit
global POSE

if isempty(POSE) || ~isfield(POSE,'initialized') ||(POSE.initialized ~= 1)
  POSE.msgName = [GetRobotName '/Pose'];
  POSE.pose = [];
  POSE.xInit = 0;
  POSE.yInit = 0;
  
  ipcInit;
  ipcAPIDefine(POSE.msgName,MagicPoseSerializer('getFormat'));
  POSE.initialized  = 1;
  disp('Pose initialized');
end