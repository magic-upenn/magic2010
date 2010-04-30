function PublishExplorationMap
global EMAP

content = VisMap2DSerializer('serialize',EMAP);
ipcAPIPublishVC(EMAP.msgName,content);
