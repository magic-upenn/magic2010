function emapInit
global EMAP

if isempty(EMAP) || (EMAP.initialized ~= 1)

  EMAP.res        = 0.05;
  EMAP.invRes     = 1/EMAP.res;
  EMAP.xmin       = -40;
  EMAP.ymin       = -40;
  EMAP.xmax       = 40;
  EMAP.ymax       = 40;
  EMAP.zmin       = 0;
  EMAP.zmax       = 5;

  EMAP.map.sizex  = (EMAP.xmax - EMAP.xmin) / EMAP.res + 1;
  EMAP.map.sizey  = (EMAP.ymax - EMAP.ymin) / EMAP.res + 1;
  EMAP.map.data   = zeros(EMAP.map.sizex,EMAP.map.sizey,'uint8');
  EMAP.msgName    = [GetRobotName '/ExplorationMap2D_map2d'];
  
  ipcInit;
  ipcAPIDefine(EMAP.msgName,VisMap2DSerializer('getFormat'));
  EMAP.initialized  = 1;
  disp('Exploration map initialized');
end
