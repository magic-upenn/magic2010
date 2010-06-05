function emapInit
global EMAP MAPS

if isempty(EMAP) || ~isfield(EMAP,'initialized') || (EMAP.initialized ~= 1)

  EMAP.res        = MAPS.res;
  EMAP.invRes     = MAPS.invRes;
  EMAP.xmin       = MAPS.xmin;
  EMAP.ymin       = MAPS.ymin;
  EMAP.xmax       = MAPS.xmax;
  EMAP.ymax       = MAPS.ymax;
  EMAP.zmin       = MAPS.zmin;
  EMAP.zmax       = MAPS.zmax;
  EMAP.map.sizex  = MAPS.map.sizex;
  EMAP.map.sizey  = MAPS.map.sizey;
  
  EMAP.map.data   = zeros(EMAP.map.sizex,EMAP.map.sizey,'uint8');
  EMAP.msgName    = [GetRobotName '/ExplorationMap2D_map2d'];
  
  EMAP.name       = 'Exploration Map';
  
  ipcInit;
  if checkVis, ipcAPIDefine(EMAP.msgName,VisMap2DSerializer('getFormat')); end
  EMAP.initialized  = 1;
  disp('Exploration map initialized');
end
