function lidar1Subscribe
global LIDAR1

lidar1Init;
ipcAPISubscribe(LIDAR1.msgName);
