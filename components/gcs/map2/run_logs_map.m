function run_logs_map(logdir)

  global GMAP RPOSE RNODE RCLUSTER

  more off

  gcsMapInit;  % Initialize global variables!
  gdispInit;
  
  if nargin < 1,
    logdir = '~/MAGIC2010/Logs/master/log2';
    %logdir = '~/MAGIC2010/Logs/master/hill_field2';
    logdir = '~/MAGIC2010/Logs/TowerField1a';
  end

  logname = '*_log_*.mat';
  dirList = dir([logdir '/' logname]);

  tmap = clock;
  for iLog = 1:length(dirList),
    logFile = [logdir '/' dirList(iLog).name];
    fprintf(1, 'Processing log file: %s\n', logFile);
  
    sLoad = load(logFile);
    udpLog = sLoad.LOG.UDP;
    %udpLog = sLoad.LOG.packets;

    for iUdp = 1:length(udpLog),
      pkt = deserialize(zlibUncompress(udpLog{iUdp}.data));
      %pkt = deserialize(zlibUncompress(udpLog{iUdp}));

      if ~isfield(pkt, 'type'), continue, end

      switch (pkt.type)
      case 'Pose'
        id = pkt.id;
        gcsMapPoseExternal(id, pkt);

      case 'MapUpdateH'
        id = pkt.id;

        gcsMapUpdateH(id, pkt);
      
        gcsMapFitPose(id);
        gdispRobot(id, RNODE{id}.pF(:,end));
          
      case 'MapUpdateV'
        id = pkt.id;

        gcsMapUpdateV(id, pkt);
        gmapAdd(id, RNODE{id}.n);

      otherwise
        
        disp('Unknown packet!');
      
      end

      if (etime(clock, tmap) > .2),
        tmap = clock;
        gdispMap(GMAP.im, GMAP.x, GMAP.y);

        id = 2;
        if ~isempty(RPOSE{id}),
          gps = RPOSE{id}.gps;
          disp(sprintf('Robot %d pose: sv=%d, hdop=%.2f, posFix=%d', ...
                       id, gps.numSat, gps.hdop,gps.posFix));
        end

        %{
        hold on;
        global GDISP RNODE
        pv = RNODE{2}.pF; npv = size(pv);
        iv = [max(1,npv-100):npv];
        pX = pv(1,iv) - GDISP.utmE0;
        pY = pv(2,iv) - GDISP.utmN0;
        plot(pX, pY, 'k-')
        hold off;
        %}

        drawnow;
      end
      
    end
  end
