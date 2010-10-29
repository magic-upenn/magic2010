more off

%logdir = '~/MAGIC2010/Logs/master/log2';
logdir = '~/MAGIC2010/Logs/master/hill_field';
logname = '*_log_*.mat';
dirList = dir([logdir '/' logname]);

global GMAP GDISP
global GPOSE
GPOSE = cell(10,1);

gmapInit;
rtInit;
gdispInit;

tdisp = clock;

for iLog = 1:length(dirList),
  logFile = [logdir '/' dirList(iLog).name];
  fprintf(1, 'Processing log file: %s\n', logFile);
  
  sLoad = load(logFile);
  %  udpLog = sLoad.LOG.UDP;
  udpLog = sLoad.LOG.packets;

  for iUdp = 1:length(udpLog),
    %    pkt = deserialize(zlibUncompress(udpLog{iUdp}.data));
    pkt = deserialize(zlibUncompress(udpLog{iUdp}));
    if isempty(pkt), continue, end

    % Pose packet:
    if strcmp(pkt.type, 'Pose')
      id = pkt.id;

      rtPoseData(id, pkt);
      [utmE, utmN, utmA] = rtUtm(id, pkt);
      if ~isempty(utmE),
        GPOSE{id}.x = utmE;
        GPOSE{id}.y = utmN;
        GPOSE{id}.yaw = utmA;

        gdispRobot(id, utmE, utmN, utmA);
      end

    % MapUpdateH
    elseif (strcmp(pkt.type, 'MapUpdateH'))
      id = pkt.id;
      %      if ~any(id == [2]), continue, end
      if ~isempty(GPOSE{id}),
        gmapAdd(id, pkt);
      end
      drawnow

    % MapUpdateV
    elseif (strcmp(pkt.type, 'MapUpdateV'))
      id = pkt.id;

    end

    if (etime(clock, tdisp) > 0.1),
      gdispMap(GMAP);
      drawnow;
      pause(0.02);
      tdisp = clock;
    end

  end
end
