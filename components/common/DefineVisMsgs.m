function DefineVisMsgs
global MAPS

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


mapMsgFormat = VisMap2DSerializer('getFormat');
ipcAPIDefine(MAPS.emap.msgName,mapMsgFormat);
ipcAPIDefine(MAPS.omap.msgName,mapMsgFormat);
