function omapInit
global OMAP POSE

if isempty(OMAP) || ~isfield(OMAP,'initialized') ||(OMAP.initialized ~= 1)

  OMAP.res        = 0.05;
  OMAP.invRes     = 1/OMAP.res;
  
  windowSize      = 40;
  OMAP.xmin       = POSE.xInit - windowSize;
  OMAP.ymin       = POSE.yInit - windowSize;
  OMAP.xmax       = POSE.xInit + windowSize;
  OMAP.ymax       = POSE.yInit + windowSize;
  OMAP.zmin       = 0;
  OMAP.zmax       = 5;

  OMAP.map.sizex  = (OMAP.xmax - OMAP.xmin) / OMAP.res + 1;
  OMAP.map.sizey  = (OMAP.ymax - OMAP.ymin) / OMAP.res + 1;
  OMAP.map.data   = zeros(OMAP.map.sizex,OMAP.map.sizey,'uint8');
  OMAP.msgName    = [GetRobotName '/ObstacleMap2D_map2d'];
  
  OMAP.delta.sizex = OMAP.map.sizex;
  OMAP.delta.sizey = OMAP.map.sizey;
  OMAP.delta.data  = zeros(size(OMAP.map.data),'uint8');
  
  ipcInit;
  if checkVis, ipcAPIDefine(OMAP.msgName,VisMap2DSerializer('getFormat')); end
  OMAP.initialized  = 1;
  disp('Obstacle map initialized');
end
