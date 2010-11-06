function gcsParams()
global GCS MAGIC_CONSTANTS HAVE_ROBOTS LOG_PACKETS

%ROBOT IDs
GCS.disruptor_ids = [];
GCS.sensor_ids = [1];

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

%UAV Map UTM offsets (lower left corner of the UAV map)
MAGIC_CONSTANTS.uavShiftEast = 0;
MAGIC_CONSTANTS.uavShiftNorth = 0;
MAGIC_CONSTANTS.uavMapEast = 279108-MAGIC_CONSTANTS.uavShiftEast;
MAGIC_CONSTANTS.uavMapNorth = 6129894-MAGIC_CONSTANTS.uavShiftNorth;

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
  disp('starting hotel test');
  MAGIC_CONSTANTS.mapEastMin = 272823;
  MAGIC_CONSTANTS.mapEastMax = 273056;
  MAGIC_CONSTANTS.mapNorthMin = 6126719;
  MAGIC_CONSTANTS.mapNorthMax = 6126861;
  MAGIC_CONSTANTS.mapEastOffset = 272900;
  MAGIC_CONSTANTS.mapNorthOffset = 6126780;

  %MAGIC_CONSTANTS.mapEastMin = 272900-100;
  %MAGIC_CONSTANTS.mapEastMax = 272900+130;
  %MAGIC_CONSTANTS.mapNorthMin = 6126746-100;
  %MAGIC_CONSTANTS.mapNorthMax = 6126746+140;
  %MAGIC_CONSTANTS.mapEastOffset = 272900;
  %MAGIC_CONSTANTS.mapNorthOffset = 6126746;

  %hotel lower left corner
  MAGIC_CONSTANTS.uavShiftEast = 0;
  MAGIC_CONSTANTS.uavShiftNorth = 0;
  MAGIC_CONSTANTS.uavMapEast = 272811-MAGIC_CONSTANTS.uavShiftEast;
  MAGIC_CONSTANTS.uavMapNorth = 6126671-MAGIC_CONSTANTS.uavShiftNorth;
  %MAGIC_CONSTANTS.uavMapEast = 272823-MAGIC_CONSTANTS.uavShiftEast;
  %MAGIC_CONSTANTS.uavMapNorth = 6126719-MAGIC_CONSTANTS.uavShiftNorth;

  %MAGIC_CONSTANTS.uavMapEast = 272800;
  %MAGIC_CONSTANTS.uavMapNorth = 6126646;
case 5
  disp('starting test site (Hamstead Barracks)');
  MAGIC_CONSTANTS.mapEastMin = 282404;
  MAGIC_CONSTANTS.mapEastMax = 282731;
  MAGIC_CONSTANTS.mapNorthMin = 6138571;
  MAGIC_CONSTANTS.mapNorthMax = 6138927;
  MAGIC_CONSTANTS.mapEastOffset = 282550;
  MAGIC_CONSTANTS.mapNorthOffset = 6138770;

  %hamstead lower left corner
  MAGIC_CONSTANTS.uavShiftEast = 0;
  MAGIC_CONSTANTS.uavShiftNorth = 0;
  MAGIC_CONSTANTS.uavMapEast = 282288-MAGIC_CONSTANTS.uavShiftEast;
  MAGIC_CONSTANTS.uavMapNorth = 6138563-MAGIC_CONSTANTS.uavShiftNorth;
case 6
  disp('starting uav feed test');
  MAGIC_CONSTANTS.mapEastMin = 308000;
  MAGIC_CONSTANTS.mapEastMax = 308200;
  MAGIC_CONSTANTS.mapNorthMin = 4332000;
  MAGIC_CONSTANTS.mapNorthMax = 4332200;
  MAGIC_CONSTANTS.mapEastOffset = 308100;
  MAGIC_CONSTANTS.mapNorthOffset = 4332100;
otherwise
  disp('starting custom map');
  MAGIC_CONSTANTS.mapEastMin = -100;
  MAGIC_CONSTANTS.mapEastMax = 100;
  MAGIC_CONSTANTS.mapNorthMin = -100;
  MAGIC_CONSTANTS.mapNorthMax = 100;
  MAGIC_CONSTANTS.mapEastOffset = 0;
  MAGIC_CONSTANTS.mapNorthOffset = 0;
end

MAGIC_CONSTANTS.mapSizeX = MAGIC_CONSTANTS.mapEastMax - MAGIC_CONSTANTS.mapEastMin;
MAGIC_CONSTANTS.mapSizeY = MAGIC_CONSTANTS.mapNorthMax - MAGIC_CONSTANTS.mapNorthMin;
MAGIC_CONSTANTS.mapRes = 0.1;

