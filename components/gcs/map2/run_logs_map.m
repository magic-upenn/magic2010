function run_logs_map(logdir)

  more off
  gcsMapInit;  % Initialize global variables!
  
  global GMAP RNODE
  gmapInit;
  gdispInit;
  
  if nargin < 1,
    logdir = '~/MAGIC2010/Logs/master/hill_field2';
    logdir = '~/MAGIC2010/Logs/master/hill_field';
  end

  logname = '*_log_*.mat';
  dirList = dir([logdir '/' logname]);

  tmap = clock;
  for iLog = 1:length(dirList),
    logFile = [logdir '/' dirList(iLog).name];
    fprintf(1, 'Processing log file: %s\n', logFile);
  
    sLoad = load(logFile);
    %udpLog = sLoad.LOG.UDP;
    udpLog = sLoad.LOG.packets;

    for iUdp = 1:length(udpLog),
      %pkt = deserialize(zlibUncompress(udpLog{iUdp}.data));
      pkt = deserialize(zlibUncompress(udpLog{iUdp}));
      if isempty(pkt), continue, end

      % Pose packet:
      switch(pkt.type)
        case 'Pose'

        id = pkt.id;
        gcsMapPoseExternal(id, pkt);


      case 'MapUpdateH'

        id = pkt.id;
        gcsMapUpdateH(id, pkt);
      
        if (RNODE{id}.gpsInitialized),
          gcsMapFitPose(id);
          gdispRobot(id, RNODE{id}.pF(:,end));
        end
          
      case 'MapUpdateV'

        id = pkt.id;
        gcsMapUpdateV(id, pkt);

        gmapAdd(id, RNODE{id}.n);

      otherwise
        
        disp('Unknown packet!');
      
      end

      if (etime(clock, tmap) > .5),
        tmap = clock;
        gdispMap(GMAP.im, GMAP.x, GMAP.y);
        drawnow;
      end
      
    end
  end
