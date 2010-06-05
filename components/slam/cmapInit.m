function cmapInit
global CMAP MAPS

if isempty(CMAP) || ~isfield(CMAP,'initialized') ||(CMAP.initialized ~= 1)

  CMAP.res        = MAPS.res;
  CMAP.invRes     = MAPS.invRes;
  CMAP.xmin       = MAPS.xmin;
  CMAP.ymin       = MAPS.ymin;
  CMAP.xmax       = MAPS.xmax;
  CMAP.ymax       = MAPS.ymax;
  CMAP.zmin       = MAPS.zmin;
  CMAP.zmax       = MAPS.zmax;
  CMAP.map.sizex  = MAPS.map.sizex;
  CMAP.map.sizey  = MAPS.map.sizey;
  
  CMAP.map.data   = zeros(CMAP.map.sizex,CMAP.map.sizey,'single');
  CMAP.msgName    = [GetRobotName '/CostMap2D_map2d'];
  
  CMAP.name       = 'Cost Map';
  
  ipcInit;
  if checkVis, ipcAPIDefine(CMAP.msgName,VisMap2DSerializer('getFormat')); end
  CMAP.initialized  = 1;
  disp('Obstacle map initialized');
end
