function DefineVisMsgs

pointCloudTypeName  = 'PointCloud3DColorDoubleRGBA';
pointCloudMsgName   = ['pointCloud' VisMarshall('getMsgSuffix',pointCloudTypeName)];
pointCloudFormat    = VisMarshall('getMsgFormat',pointCloudTypeName);
ipcAPIDefine(pointCloudMsgName,pointCloudFormat);

lidarPointsTypeName = 'PointCloud3DColorDoubleRGBA';
lidarPointsMsgName  = ['lidar1Points' VisMarshall('getMsgSuffix',lidarPointsTypeName)];
lidarPointsFormat   = VisMarshall('getMsgFormat',lidarPointsTypeName);
ipcAPIDefine(lidarPointsMsgName,lidarPointsFormat);


poseMsgName = [GetRobotName VisMarshall('getMsgSuffix','Pose3D')];
poseMsgFormat  = VisMarshall('getMsgFormat','Pose3D');
ipcAPIDefine(poseMsgName,poseMsgFormat);

odomPoseMsgName = [GetRobotName 'Odom' VisMarshall('getMsgSuffix','Pose3D')];
odomPoseMsgFormat  = VisMarshall('getMsgFormat','Pose3D');
ipcAPIDefine(odomPoseMsgName,odomPoseMsgFormat);

trajMsgName = [GetRobotName 'Traj' VisMarshall('getMsgSuffix','TrajPos3DColorDoubleRGBA')];
trajMsgFormat  = VisMarshall('getMsgFormat','TrajPos3DColorDoubleRGBA');
ipcAPIDefine(trajMsgName,trajMsgFormat);
