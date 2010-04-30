function omapInit
global OMAP

if isempty(OMAP) || (OMAP.initialized ~= 1)

  OMAP.res        = 0.05;
  OMAP.invRes     = 1/OMAP.res;
  OMAP.xmin       = -25;
  OMAP.ymin       = -25;
  OMAP.xmax       = 25;
  OMAP.ymax       = 25;
  OMAP.zmin       = 0;
  OMAP.zmax       = 5;

  OMAP.map.sizex  = (OMAP.xmax - OMAP.xmin) / OMAP.res;
  OMAP.map.sizey  = (OMAP.ymax - OMAP.ymin) / OMAP.res;
  OMAP.map.data   = zeros(OMAP.map.sizex,OMAP.map.sizey,'uint8');
  OMAP.msgName    = [GetRobotName '/ObstacleMap2D_map2d'];
  
  ipcInit;
  ipcAPIDefine(OMAP.msgName,VisMap2DSerializer('getFormat'));
  OMAP.initialized  = 1;
  disp('Obstacle map initialized');
end