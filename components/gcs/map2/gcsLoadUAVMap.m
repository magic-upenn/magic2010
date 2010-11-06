function gcsLoadUAVMap()
global UAV_MAP MAGIC_CONSTANTS

if MAGIC_CONSTANTS.scenario == 4
  %hotel map
  disp('loading UAV hotel map');
  img = imread('bigHotelEdgeMap2.jpg');
else
  %Magic 2010 map
  disp('loading UAV MAGIC map');
  img = imread('uavEdgeMap.jpg');
end

UAV_MAP = img;

[ny, nx] = size(img);
x1uav = MAGIC_CONSTANTS.uavMapEast + ...
        [0:nx-1]*MAGIC_CONSTANTS.mapRes;
y1uav = MAGIC_CONSTANTS.uavMapNorth + ...
        [ny-1:-1:0]*MAGIC_CONSTANTS.mapRes;

[iuav, juav] = find(img);
xuav = x1uav(juav);
yuav = y1uav(iuav);

xshift = 0;
yshift = 0;

xuav = xuav + xshift;
yuav = yuav + yshift;

global GMAP
map_assign(GMAP.im0, GMAP.x, GMAP.y, [xuav; yuav; -20*ones(size(xuav))]);


%{
xCells = ceil(MAGIC_CONSTANTS.mapSizeX/MAGIC_CONSTANTS.mapRes);
yCells = ceil(MAGIC_CONSTANTS.mapSizeY/MAGIC_CONSTANTS.mapRes);
x0 = round((MAGIC_CONSTANTS.mapEastMin - MAGIC_CONSTANTS.uavMapEast)/MAGIC_CONSTANTS.mapRes)+1;
x1 = x0+xCells-1;
y0 = size(img,1)-round((MAGIC_CONSTANTS.mapNorthMin - MAGIC_CONSTANTS.uavMapNorth)/MAGIC_CONSTANTS.mapRes);
y1 = y0-yCells+1;
UAV_MAP = double(img(y0:-1:y1,x0:x1)');
UAV_MAP(UAV_MAP>0) = 1;
%}
