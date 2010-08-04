function publishTarget(target)

msgName = 'Robot3/Target';
ipcAPIConnect;
ipcAPIDefine(msgName);

pose.x = target(1);
pose.y = target(2);
pose.z = target(3);

ipcAPIPublish(msgName,MagicPoseSerializer('serialize',pose));

