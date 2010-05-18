function omapInit
global OMAP

if isempty(OMAP) || ~isfield(OMAP,'initialized') ||(OMAP.initialized ~= 1)

  OMAP.res        = 0.05;
  OMAP.invRes     = 1/OMAP.res;
  
  
  OMAP.xmin       = -40;
  OMAP.ymin       = -40;
  OMAP.xmax       = 40;
  OMAP.ymax       = 40;
  OMAP.zmin       = 0;
  OMAP.zmax       = 5;

  OMAP.map.sizex  = (OMAP.xmax - OMAP.xmin) / OMAP.res + 1;
  OMAP.map.sizey  = (OMAP.ymax - OMAP.ymin) / OMAP.res + 1;
  OMAP.map.data   = zeros(OMAP.map.sizex,OMAP.map.sizey,'uint8');
  OMAP.msgName    = [GetRobotName '/ObstacleMap2D_map2d'];
  
  ipcInit;
  ipcAPIDefine(OMAP.msgName,VisMap2DSerializer('getFormat'));
  OMAP.initialized  = 1;
  disp('Obstacle map initialized');
end