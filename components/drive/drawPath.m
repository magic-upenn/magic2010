global POSE
POSE.data = [];

ipcInit;

ipcReceiveSetFcn(GetMsgName('Pose'), @ipcRecvPoseFcn);
while isempty(POSE.data),
  ipcReceiveMessages;
end

clf;
plotRobot(POSE.data.x, POSE.data.y, POSE.data.yaw, 1);
axis([POSE.data.x+[-5 5] POSE.data.y+[-5 5]]);
axis square

DRIVE.speed = .5;
DRIVE.path = ginput;

driveMsgName = GetMsgName('Drive');
ipcAPIDefine(driveMsgName);

ipcAPIPublish(driveMsgName, serialize(DRIVE));
