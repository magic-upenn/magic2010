function poseInit
global POSE

if isempty(POSE) || (POSE.initialized ~= 1)
  POSE.msgName = [GetRobotName '/Pose'];
  POSE.pose = [];
  
  ipcInit;
  ipcAPIDefine(POSE.msgName,MagicPoseSerializer('getFormat'));
  POSE.initialized  = 1;
  disp('Pose initialized');
end