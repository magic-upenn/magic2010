function lidar0Subscribe
global LIDAR0

lidar0Init;
ipcAPISubscribe(LIDAR0.msgName);
