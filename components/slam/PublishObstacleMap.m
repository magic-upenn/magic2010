function PublishObstacleMap
global MAPS

content = VisMap2DSerializer('serialize',MAPS.omap);
ipcAPIPublishVC(MAPS.omap.msgName,content);
