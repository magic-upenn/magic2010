more off

logdir = '~/MAGIC2010/Logs/master/log2';
logname = 'gcs_log*.mat';
dirList = dir([logdir '/' logname]);

global GPOSE
GPOSE = cell(10,1);

gdispInit;
rtInit;

for iLog = 1:length(dirList),
  logFile = [logdir '/' dirList(iLog).name];
  fprintf(1, 'Processing log file: %s\n', logFile);
  
  sLoad = load(logFile);
  udpLog = sLoad.LOG.UDP;

  for iUdp = 1:length(udpLog),
    pkt = deserialize(zlibUncompress(udpLog{iUdp}.data));
    if isfield(pkt, 'gps'),
      id = pkt.id;

      rtPoseData(id, pkt);
      [utmE, utmN, utmA] = rtUtm(id, pkt);

      if ~isempty(utmE),
        GPOSE{id}.x = utmE;
        GPOSE{id}.y = utmN;
        GPOSE{id}.yaw = utmA;

        gdispRobot(id, utmE, utmN, utmA);
      end
      drawnow
    end
  end
end
