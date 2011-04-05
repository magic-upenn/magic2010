function poseInit
global POSE

if isempty(POSE) || ~isfield(POSE,'initialized') ||(POSE.initialized ~= 1)
  POSE.msgName    = [GetRobotName '/Pose'];
  POSE.extMsgName = [GetRobotName '/PoseExternal']; 
  POSE.pose = [];
  POSE.data.x       = 0;
  POSE.data.y       = 0;
  POSE.data.z       = 0;
  POSE.data.roll    = 0;
  POSE.data.pitch   = 0;
  POSE.data.yaw     = 0;
  
  ipcInit;
  ipcAPIDefine(POSE.msgName,MagicPoseSerializer('getFormat'));
  ipcAPIDefine(POSE.extMsgName,MagicPoseSerializer('getFormat'));
  POSE.initialized  = 1;
  disp('Pose initialized');
end