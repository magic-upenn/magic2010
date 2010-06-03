function cmapInit
global CMAP POSE

if isempty(CMAP) || ~isfield(CMAP,'initialized') ||(CMAP.initialized ~= 1)

  CMAP.res        = 0.05;
  CMAP.invRes     = 1/CMAP.res;
  
  windowSize      = 40;
  CMAP.xmin       = POSE.xInit - windowSize;
  CMAP.ymin       = POSE.yInit - windowSize;
  CMAP.xmax       = POSE.xInit + windowSize;
  CMAP.ymax       = POSE.yInit + windowSize;
  CMAP.zmin       = 0;
  CMAP.zmax       = 5;

  CMAP.map.sizex  = (CMAP.xmax - CMAP.xmin) / CMAP.res + 1;
  CMAP.map.sizey  = (CMAP.ymax - CMAP.ymin) / CMAP.res + 1;
  CMAP.map.data   = zeros(CMAP.map.sizex,CMAP.map.sizey,'single');
  CMAP.msgName    = [GetRobotName '/CostMap2D_map2d'];
  
  ipcInit;
  if checkVis, ipcAPIDefine(CMAP.msgName,VisMap2DSerializer('getFormat')); end
  CMAP.initialized  = 1;
  disp('Obstacle map initialized');
end
