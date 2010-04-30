function emapInit
global EMAP

if isempty(EMAP) || (EMAP.initialized ~= 1)

  EMAP.res        = 0.05;
  EMAP.invRes     = 1/EMAP.res;
  EMAP.xmin       = -25;
  EMAP.ymin       = -25;
  EMAP.xmax       = 25;
  EMAP.ymax       = 25;
  EMAP.zmin       = 0;
  EMAP.zmax       = 5;

  EMAP.map.sizex  = (EMAP.xmax - EMAP.xmin) / EMAP.res;
  EMAP.map.sizey  = (EMAP.ymax - EMAP.ymin) / EMAP.res;
  EMAP.map.data   = 127*ones(EMAP.map.sizex,EMAP.map.sizey,'uint8');
  EMAP.msgName    = [GetRobotName '/ExplorationMap2D_map2d'];
  
  ipcInit;
  ipcAPIDefine(EMAP.msgName,VisMap2DSerializer('getFormat'));
  EMAP.initialized  = 1;
  disp('Exploration map initialized');
end