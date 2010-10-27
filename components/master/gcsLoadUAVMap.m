function gcsLoadUAVMap()
global UAV_MAP MAGIC_CONSTANTS GMAP

img = imread('uavEdgeMap.jpg');
xCells = round(MAGIC_CONSTANTS.mapSizeX/MAGIC_CONSTANTS.mapRes);
yCells = round(MAGIC_CONSTANTS.mapSizeY/MAGIC_CONSTANTS.mapRes);
x0 = round((MAGIC_CONSTANTS.mapEastMin - MAGIC_CONSTANTS.uavMapEast)/MAGIC_CONSTANTS.mapRes);
x1 = x0+xCells-1; %round((MAGIC_CONSTANTS.mapEastMax - MAGIC_CONSTANTS.uavMapEast)/MAGIC_CONSTANTS.mapRes);
y0 = size(img,1)-round((MAGIC_CONSTANTS.mapNorthMin - MAGIC_CONSTANTS.uavMapNorth)/MAGIC_CONSTANTS.mapRes);
y1 = y0-yCells+1; %size(img,1)-round((MAGIC_CONSTANTS.mapNorthMax - MAGIC_CONSTANTS.uavMapNorth)/MAGIC_CONSTANTS.mapRes);
UAV_MAP = double(img(y0:-1:y1,x0:x1)');
UAV_MAP(UAV_MAP>0) = 1;
%UAV_MAP = UAV_MAP/max(max(UAV_MAP))*1;

