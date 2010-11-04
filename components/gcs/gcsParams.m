function gcsParams()
global GCS MAGIC_CONSTANTS HAVE_ROBOTS LOG_PACKETS

%ROBOT IDs
GCS.disruptor_ids = [];
GCS.sensor_ids = [2];

%OOI AVOID RANGES
MAGIC_CONSTANTS.ooi_range = 3.5;
MAGIC_CONSTANTS.poi_range = 6.0;

%REAL ROBOTS? (or simulation?)
HAVE_ROBOTS = true;

%LOG PACKETS?
LOG_PACKETS.enabled = true;

%MAP
MAGIC_CONSTANTS.scenario = 5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Parameters computed from the above

%ids
GCS.ids = [GCS.disruptor_ids GCS.sensor_ids];

%map params based on scenario
switch MAGIC_CONSTANTS.scenario
case 1
  disp('starting phase 1');
  MAGIC_CONSTANTS.mapEastMin = 279398;
  MAGIC_CONSTANTS.mapEastMax = 279648;
  MAGIC_CONSTANTS.mapNorthMin = 6130144;
  MAGIC_CONSTANTS.mapNorthMax = 6130324;
  MAGIC_CONSTANTS.mapEastOffset = 279443;
  MAGIC_CONSTANTS.mapNorthOffset = 6130294;
case 2
  disp('starting phase 2');
  MAGIC_CONSTANTS.mapEastMin = 279418;
  MAGIC_CONSTANTS.mapEastMax = 279678;
  MAGIC_CONSTANTS.mapNorthMin = 6129994;
  MAGIC_CONSTANTS.mapNorthMax = 6130194;
  MAGIC_CONSTANTS.mapEastOffset = 279522;
  MAGIC_CONSTANTS.mapNorthOffset = 6130135;
case 3
  disp('starting phase 3');
  MAGIC_CONSTANTS.mapEastMin = 279158;
  MAGIC_CONSTANTS.mapEastMax = 279458;
  MAGIC_CONSTANTS.mapNorthMin = 6129974;
  MAGIC_CONSTANTS.mapNorthMax = 6130314;
  MAGIC_CONSTANTS.mapEastOffset = 279438;
  MAGIC_CONSTANTS.mapNorthOffset = 6130046;
case 4
  disp('starting uav feed test');
  MAGIC_CONSTANTS.mapEastMin = 308000;
  MAGIC_CONSTANTS.mapEastMax = 308200;
  MAGIC_CONSTANTS.mapNorthMin = 4332000;
  MAGIC_CONSTANTS.mapNorthMax = 4332200;
  MAGIC_CONSTANTS.mapEastOffset = 308100;
  MAGIC_CONSTANTS.mapNorthOffset = 4332100;
case 5
  disp('starting hotel test');
  MAGIC_CONSTANTS.mapEastMin = 272900-100;
  MAGIC_CONSTANTS.mapEastMax = 272900+100;
  MAGIC_CONSTANTS.mapNorthMin = 6126746-100;
  MAGIC_CONSTANTS.mapNorthMax = 6126746+100;
  MAGIC_CONSTANTS.mapEastOffset = 272900;
  MAGIC_CONSTANTS.mapNorthOffset = 6126746;
otherwise
  disp('starting custom map');
  MAGIC_CONSTANTS.mapEastMin = -40;
  MAGIC_CONSTANTS.mapEastMax = 40;
  MAGIC_CONSTANTS.mapNorthMin = -40;
  MAGIC_CONSTANTS.mapNorthMax = 40;
  MAGIC_CONSTANTS.mapEastOffset = 0;
  MAGIC_CONSTANTS.mapNorthOffset = 0;
end

%UAV Map UTM offsets (lower left corner of the UAV map)
MAGIC_CONSTANTS.uavMapEast = 279108;
MAGIC_CONSTANTS.uavMapNorth = 6129894;

MAGIC_CONSTANTS.mapSizeX = MAGIC_CONSTANTS.mapEastMax - MAGIC_CONSTANTS.mapEastMin;
MAGIC_CONSTANTS.mapSizeY = MAGIC_CONSTANTS.mapNorthMax - MAGIC_CONSTANTS.mapNorthMin;
MAGIC_CONSTANTS.mapRes = 0.1;

