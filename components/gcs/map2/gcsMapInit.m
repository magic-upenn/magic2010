function gcsMapInit(arg)

global RPOSE RNODE RCLUSTER

nRobot = 9;

RPOSE = cell(nRobot,1);
RNODE = cell(nRobot,1);
RCLUSTER = cell(nRobot,1);

global GPOSE

GPOSE = cell(nRobot,1);

global GTRANSFORM

GTRANSFORM = cell(nRobot,1);

global MAGIC_CONSTANTS
global GMAP
if ~isempty(MAGIC_CONSTANTS),
  mapEastMin = MAGIC_CONSTANTS.mapEastMin;
  mapEastMax = MAGIC_CONSTANTS.mapEastMax;
  mapNorthMin = MAGIC_CONSTANTS.mapNorthMin;
  mapNorthMax = MAGIC_CONSTANTS.mapNorthMax;
  mapEastOffset = MAGIC_CONSTANTS.mapEastOffset;
  mapNorthOffset = MAGIC_CONSTANTS.mapNorthOffset;  
else
  [utmE, utmN, utmZone] = deg2utm(39.9524, -75.1915);
  [utmE, utmN, utmZone] = deg2utm(-34.9764, 138.5123);
  mapEastMin = utmE-100.0;
  mapEastMax = utmE+100.0;
  mapNorthMin = utmN-100.0;
  mapNorthMax = utmN+100.0;  
  mapEastOffset = utmE;
  mapNorthOffset = utmN;
end

GMAP.x = [mapEastMin mapEastMax];
GMAP.y = [mapNorthMin mapNorthMax];
GMAP.x0 = mapEastOffset;
GMAP.y0 = mapNorthOffset;

resolution = 0.10;
nx = (GMAP.x(end)-GMAP.x(1))/resolution + 0;
ny = (GMAP.y(end)-GMAP.y(1))/resolution + 0;

GMAP.im = zeros(nx, ny, 'int8');

GMAP.im0 = zeros(nx, ny, 'int8');
GMAP.rnodeN0 = cell(nRobot,1);
GMAP.rnodeN = cell(nRobot,1);
