function run_logs_map2(logdir)

  global GMAP
  global GPOSE
  global RPOSE RNODE RCLUSTER
  
  more off

  % Load scenario parameters
  %gcsParams;

  % Initialize global variables
  gcsMapInit;
  gdispInit;
  
  if nargin < 1,
    %logdir = '~/MAGIC2010/Logs/master/log2';
    %logdir = '~/MAGIC2010/Logs/master/hill_field2';
    %logdir = '~/MAGIC2010/Logs/Hampstead2';
    logdir = '~/MAGIC2010/Logs/Phase2';
  end

  logname = '*_log_*.mat';
  dirList = dir([logdir '/' logname]);

  tmap = gettime;
  tdisp = gettime;
  tprocess = gettime;
  nprocess = 0;

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
      case 'SlamPoseMap'
        id = pkt.id;
        gcsMapPoseExternal(id, pkt.pose);

        nprocess = nprocess+1;
        if (rem(nprocess,100) == 0)
          disp(sprintf('nprocess: %d, %.1f sec', ...
                       nprocess, gettime-tprocess));
          tprocess = gettime;
        end

        % Need pose first for MapUpdateH
        if isempty(RPOSE{id}),
          disp(sprintf('MapUpdateH: waiting for pose on robot %d', id));
          continue;
        end
        gcsMapUpdateH(id, pkt.hlidar);
        gcsMapFitPose(id);

        %gdispRobot(id, RNODE{id}.pF(:,end));
        gdispRobot(id, GPOSE{id});

        % Need MapUpdateH to first initialize RNODE
        if isempty(RNODE{id}),
          disp(sprintf('MapUpdateV: waiting for RNODE on robot %d', id));
          continue;
        end

        gcsMapUpdateV(id, pkt.vlidar);
        gmapAdd(id, RNODE{id}.n);


      otherwise
        
        disp('Unknown packet!');
      
      end

      if (gettime-tmap) > 5,
        tmap = gettime;
        gmapRecalc;
      end

      if (gettime-tdisp) > .5,
        tdisp = gettime;
        gdispMap(GMAP.im, GMAP.x, GMAP.y);

        %{
        id = 1;
        if ~isempty(RPOSE{id}),
          gps = RPOSE{id}.gps;
          disp(sprintf('Robot %d pose: sv=%d, hdop=%.2f, posFix=%d', ...
                       id, gps.numSat, gps.hdop,gps.posFix));
        end
        %}

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
