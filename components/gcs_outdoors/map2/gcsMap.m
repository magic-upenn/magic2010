function gcsMap(log_file)
more off;

%load parameters
gcsParams;

global LOG_PACKETS INIT_LOG RPOSE GPOSE GMAP GTRANSFORM MAGIC_CONSTANTS

%load from a Log file?
if nargin > 0
  disp('Starting GCS MAP from LOG');
  INIT_LOG = true;
  load(log_file);
else
  disp('Starting GCS MAP from scratch');
  INIT_LOG = false;
end


global gcs_machine GCS HAVE_ROBOTS UAV_MAP

tUpdate = 0.1;

%connect to UDP
addr = '192.168.10.220';
port = 12346;
UdpReceiveAPI('connect',addr,port);

%connect to IPC
gcs_machine.ipcAPI = str2func('ipcAPI');
gcs_machine.ipcAPI('connect');
gcs_machine.ipcAPI('define','Global_Map');
gcs_machine.ipcAPI('define','RPose');
gcs_machine.ipcAPI('define','IncH');
gcs_machine.ipcAPI('define','IncV');

gcsLogPackets('entry');

xCells = round(MAGIC_CONSTANTS.mapSizeX/MAGIC_CONSTANTS.mapRes);
yCells = round(MAGIC_CONSTANTS.mapSizeY/MAGIC_CONSTANTS.mapRes);
xShift = (MAGIC_CONSTANTS.mapEastMax+MAGIC_CONSTANTS.mapEastMin)/2-MAGIC_CONSTANTS.mapEastOffset;
yShift = (MAGIC_CONSTANTS.mapNorthMax+MAGIC_CONSTANTS.mapNorthMin)/2-MAGIC_CONSTANTS.mapNorthOffset;

%init poses and transforms
for id = GCS.ids,
  if ~INIT_LOG
    RPOSE{id}.x = 0;
    RPOSE{id}.y = 0;
    RPOSE{id}.yaw = 0;
    RPOSE{id}.heading = 0;

    if HAVE_ROBOTS
      GTRANSFORM{id}.init = 0;
      GPOSE{id} = [];
    else
      GTRANSFORM{id}.init = 1;
      GTRANSFORM{id}.dx = 0;
      GTRANSFORM{id}.dy = 0;
      GTRANSFORM{id}.dyaw = 0;

      GPOSE{id}.x = 0;
      GPOSE{id}.y = 0;
      GPOSE{id}.yaw = 0;
    end
  end
end

%init global map
if ~INIT_LOG
  GMAP = map2d(xCells, yCells, MAGIC_CONSTANTS.mapRes, 'hlidar', 'cost');
  GMAP = shift(GMAP,xShift,yShift);
  if MAGIC_CONSTANTS.scenario >= 1 && MAGIC_CONSTANTS.scenario <= 3
    %load the UAV prior
    gcsLoadUAVMap();
    GMAP = setdata(GMAP, 'cost', UAV_MAP);
  end
end

last_log_time = gettime;

%main loop
while 1,
  pause(tUpdate);

  %receive packets
  packets = UdpReceiveAPI('receive');
  gcsLogPackets('UDP',packets);
  n = length(packets);
  if n > 0
    for ii=1:n
      fprintf(1,'got packet of size %d\n',length(packets(ii).data));
      packet = deserialize(zlibUncompress(packets(ii).data));
      if ~isfield(packet,'type'), continue, end
      if ~ischar(packet.type), continue, end

      switch(packet.type)
      case 'Pose'
        gcsRecvPoseExternal(packet,packet.id);
      case 'MapUpdateH'
        gcsRecvIncMapUpdateH(packet,packet.id);
      case 'MapUpdateV'
        gcsRecvIncMapUpdateV(packet,packet.id);
      end
    end
  end

  %send global map
  msg.mapData = getdata(GMAP,'cost');
  msg.GTRANSFORM = GTRANSFORM;
  msg.GPOSE = GPOSE;
  gcs_machine.ipcAPI('publish','Global_Map',serialize(msg));
  
  %save a backup log periodically
  if (gettime - last_log_time) > 60.0
    savefile = ['/tmp/gcs_map_', datestr(clock,30)];
    disp(sprintf('Saving map file: %s', savefile));
    eval(['save ' savefile ' RPOSE GPOSE GMAP GTRANSFORM MAGIC_CONSTANTS']);
    last_log_time = gettime;
  end
end

