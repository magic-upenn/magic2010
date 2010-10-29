more off

%logdir = '~/MAGIC2010/Logs/master/log2';
logdir = '~/MAGIC2010/Logs/master/hill_field';
logname = '*_log_*.mat';
dirList = dir([logdir '/' logname]);

gdispInit;

DAT = [];

for iLog = 1:length(dirList),
  logFile = [logdir '/' dirList(iLog).name];
  fprintf(1, 'Processing log file: %s\n', logFile);
  
  sLoad = load(logFile);
  %  udpLog = sLoad.LOG.UDP;
  udpLog = sLoad.LOG.packets;

  for iUdp = 1:length(udpLog),
    %    pkt = deserialize(zlibUncompress(udpLog{iUdp}.data));
    pkt = deserialize(zlibUncompress(udpLog{iUdp}));
    if isfield(pkt, 'gps'),
      id = pkt.id;
      gps = pkt.gps;
%      fprintf(1, 'GPS %d: %d sat, %.3f hdop\n', id, gps.numSat, gps.hdop);

      if ~gps.valid, continue, end
      %      if gps.numSat < 7, continue, end
      %      if gps.hdop > 1.5, continue, end
      if isempty(gps.heading), continue, end

      fprintf(1, 'GPS %d: %d sat, %.1f hdop, %.1f speed, %d fix\n', id, ...
              gps.numSat, gps.hdop, gps.speed,gps.posFix);
      [utmE, utmN, utmZone] = deg2utm(gps.lat, gps.lon);
      utmA = modAngle(pi/2-gps.heading);
      gdispRobot(id, utmE, utmN, utmA);
      drawnow;

      if (id == 3),
        DAT(:,end+1) = [utmE utmN utmA]';
      end

    end
  end
end
