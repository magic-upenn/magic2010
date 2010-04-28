function PublishExplorationMap
global MAPS

content = VisMap2DSerializer('serialize',MAPS.emap);
ipcAPIPublishVC(MAPS.emap.msgName,content);
