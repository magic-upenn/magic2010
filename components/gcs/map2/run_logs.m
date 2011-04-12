function run_logs(logdir)

  more off
  gcsMapInit;  % Initialize global variables!
  
  if nargin < 1,
    %logdir = '~/MAGIC2010/Logs/master/log2';
    %logdir = '~/MAGIC2010/Logs/master/hill_field2';
    logdir = '~/MAGIC2010/Logs/master/hill_field';
  end

  logname = '*_log_*.mat';
  dirList = dir([logdir '/' logname]);

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
        gcsMapPoseExternal(id, pkt);

        % MapUpdateH
      elseif (strcmp(pkt.type, 'MapUpdateH'))

        id = pkt.id;
        gcsMapUpdateH(id, pkt);
      
        gcsMapFitPose(id);
        plot_paths(id);
        
      elseif (strcmp(pkt.type, 'MapUpdateV'))

        id = pkt.id;
        gcsMapUpdateV(id, pkt);
        
      else
        
        disp('Unknown packet!');
      
      end
    end
  end
