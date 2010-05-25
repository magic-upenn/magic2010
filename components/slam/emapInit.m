function emapInit
global EMAP POSE

if isempty(EMAP) || ~isfield(EMAP,'initialized') || (EMAP.initialized ~= 1)

  EMAP.res        = 0.05;
  EMAP.invRes     = 1/EMAP.res;

  windowSize      = 40;
  EMAP.xmin       = POSE.xInit - windowSize;
  EMAP.ymin       = POSE.yInit - windowSize;
  EMAP.xmax       = POSE.xInit + windowSize;
  EMAP.ymax       = POSE.yInit + windowSize;
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
