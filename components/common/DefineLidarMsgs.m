lidar0MsgName = [GetRobotName '/Lidar0'];
lidar1MsgName = [GetRobotName '/Lidar1'];
lidar2MsgName = [GetRobotName '/Lidar2'];

ipcAPIDefine(lidar0MsgName,MagicLidarScanSerializer('getFormat'));
ipcAPIDefine(lidar1MsgName,MagicLidarScanSerializer('getFormat'));
ipcAPIDefine(lidar2MsgName,MagicLidarScanSerializer('getFormat'));