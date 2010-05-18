SetMagicPaths;

ipcAPIConnect;
ipcAPIDefine('Robot0/Lidar0',MagicLidarScanSerializer('getFormat'));
ipcAPIDefine('Robot0/Lidar1',MagicLidarScanSerializer('getFormat'));
ipcAPIDefine('Robot0/Lidar2',MagicLidarScanSerializer('getFormat'));
ipcAPIDefine('Robot0/Servo1',MagicServoStateSerializer('getFormat'));
ipcAPIDefine('Robot0/Encoders',MagicEncoderCountsSerializer('getFormat'));
ipcAPIDefine('Robot0/ImuFiltered',MagicImuFilteredSerializer('getFormat'));
ipcAPIDefine('Robot0/GPS',MagicGpsASCIISerializer('getFormat'));
ipcAPIDefine('Robot0/HeartBeat',MagicHeartBeatSerializer('getFormat'));