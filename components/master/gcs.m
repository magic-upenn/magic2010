function gcs(log_type,log_file)
more off;

% load up from a log file (possibly)
global INIT_LOG INIT_REGIONS RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI
if nargin > 0
  switch log_type
  case 'full'
    disp('Starting GCS from FULL LOG');
    INIT_LOG = true;
    INIT_REGIONS = false;
    load(log_file);
  case 'regions'
    disp('Starting GCS with REGION LOG');
    INIT_LOG = false;
    INIT_REGIONS = true;
    load(log_file);
  otherwise
    disp('WARNING: Unrecognized log type! Starting GCS from scratch');
    INIT_LOG = false;
    INIT_REGIONS = false;
  end
else
  disp('Starting GCS from scratch');
  INIT_LOG = false;
  INIT_REGIONS = false;
end

%%%  gcs stuff
global gcs_machine Robots GCS MAGIC_CONSTANTS HAVE_ROBOTS LOG_PACKETS
last_gcs_update = gettime;
last_uav_update = gettime;

gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
ipcReceiveSetFcn('Global_Planner_TRAJ',@GPTRAJHandler,gcs_machine.ipcAPI,1);
gcs_machine.ipcAPI('define','Global_Planner_DATA',  MagicGP_DATASerializer('getFormat'));
ipcReceiveSetFcn('OOI_Msg',@gcsRecvOOIFcn,gcs_machine.ipcAPI,1);
ipcReceiveSetFcn('OOI_Done_Msg',@gcsRecvOOIDoneFcn,gcs_machine.ipcAPI,1);

tUpdate = 0.1;

%ROBOT IDs
GCS.disruptor_ids = [];
GCS.sensor_ids = [1];
ids = [GCS.disruptor_ids GCS.sensor_ids];

%OOI AVOID RANGES
MAGIC_CONSTANTS.ooi_range = 3.5;
MAGIC_CONSTANTS.poi_range = 6.0;

%MAP SIZE
MAGIC_CONSTANTS.scenario = 5;
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
otherwise
  disp('starting custom map');
  MAGIC_CONSTANTS.mapEastMin = -100;
  MAGIC_CONSTANTS.mapEastMax = 100;
  MAGIC_CONSTANTS.mapNorthMin = -100;
  MAGIC_CONSTANTS.mapNorthMax = 100;
  MAGIC_CONSTANTS.mapEastOffset = 0;
  MAGIC_CONSTANTS.mapNorthOffset = 0;
end

%UAV Map UTM offsets (lower left corner of the UAV map)
MAGIC_CONSTANTS.uavMapEast = 279108;
MAGIC_CONSTANTS.uavMapNorth = 6129894;

MAGIC_CONSTANTS.mapSizeX = MAGIC_CONSTANTS.mapEastMax - MAGIC_CONSTANTS.mapEastMin;
MAGIC_CONSTANTS.mapSizeY = MAGIC_CONSTANTS.mapNorthMax - MAGIC_CONSTANTS.mapNorthMin;
MAGIC_CONSTANTS.mapRes = 0.1;

%REAL ROBOTS? (or simulation?)
HAVE_ROBOTS = true;

%LOG PACKETS?
LOG_PACKETS.enabled = false;

gcsLogPackets('entry');

for id = ids,
  Robots(id).traj.handle = -1;
end

initExploreTemplates();
if MAGIC_CONSTANTS.scenario <= 3
  gcsLoadUAVMap();
end
gcsEntryIPC(ids)
mapDisplay('entry');
gcsUAVFeed('entry');

while 1,
  pause(tUpdate);
  gcsUpdateIPC;
  mapDisplay('update');
  if ((gettime - last_gcs_update > 3.0) && HAVE_ROBOTS)
    sendMapToExploration;
    last_gcs_update = gettime;
  end
  if ((gettime - last_uav_update > 1.0))
    %gcsUAVFeed('update');
    last_uav_update = gettime;
  end
end

end

