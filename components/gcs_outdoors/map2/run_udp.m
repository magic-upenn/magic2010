function run_udp(log_file)

  more off

  % Load scenario parameters
  gcsParams;

  global GMAP GPOSE GTRANSFORM GDISP RPOSE RNODE RCLUSTER RCLUSTER_INFO IPC_OUTPUT 

  %load up from a log file (possibly)
  if nargin > 0
    disp('Starting GCS Map from LOG');
    load(log_file);
  else
    disp('Starting GCS Map from scratch');

    % Initialize global variables
    gcsMapInit;
  end
  
  gdispInit;
  
  % Setup IPC output
  gcsMapIPCInit(true);

  gcsLogPackets('entry');

  % Connect to UDP
  addr = '192.168.10.220';
  port = 12346;
  UdpReceiveAPI('connect', addr, port);

  tmap = gettime;
  tIpc = gettime;
  tProcess = gettime;
  nProcess = 0;

  while 1,
    pause(.02);

    saveLog;

    packets = UdpReceiveAPI('receive');
    gcsLogPackets('UDP', packets);
    n = length(packets);
    for ii = 1:n,
      try
        pkt = deserialize(zlibUncompress(packets(ii).data));
      catch
        disp('Error in deserialize/uncompress packet!');
        continue;
      end

      if ~isfield(pkt, 'type'), continue, end

      switch (pkt.type)
      case 'SlamPoseMap'
        id = pkt.id;

        % send subfields to IPC
        forwardPose(pkt.pose,id);
        forwardIncH(pkt.hlidar,id);
        forwardIncV(pkt.vlidar,id);
        
        gcsMapPoseExternal(id, pkt.pose);

        if isempty(RPOSE{id}),
          disp(sprintf('MapUpdateH: waiting for pose on robot %d', id));
        else
          gcsMapUpdateH(id, pkt.hlidar);
          gcsMapFitPose(id);
          %gdispRobot(id, RNODE{id}.pF(:,end));
          gdispRobot(id, GPOSE{id});
        end
        
        % Need MapUpdateH to first initialize RNODE
        if isempty(RNODE{id}),
          disp(sprintf('MapUpdateV: waiting for RNODE on robot %d', id));
        else
          gcsMapUpdateV(id, pkt.vlidar);
          if (id < 6), % no disrupters
            gmapAdd(id, RNODE{id}.n);
          end
        end

        nProcess = nProcess+1;
        if (rem(nProcess, 100) == 0),
          disp(sprintf('map2: %d fits, %.2f sec', ...
                       nProcess, gettime-tProcess));
          tProcess = gettime;
        end

        %{
      case 'Pose'
      % Pose packet:

        id = pkt.id;
        forwardPose(pkt,id);
        gcsMapPoseExternal(id, pkt);

      case 'MapUpdateH'

        id = pkt.id;

        forwardIncH(pkt,id);
        % Need pose first for MapUpdateH
        if isempty(RPOSE{id}),
          disp(sprintf('MapUpdateH: waiting for pose on robot %d', id));
          break;
        end

        gcsMapUpdateH(id, pkt);
        gcsMapFitPose(id);
 
        %gdispRobot(id, RNODE{id}.pF(:,end));
        gdispRobot(id, GPOSE{id});

        nProcess = nProcess+1;
        if (rem(nProcess, 100) == 0),
          disp(sprintf('map2: %d fits, %.2f sec', ...
                       nProcess, gettime-tProcess));
          tProcess = gettime;
        end
          
      case 'MapUpdateV'

        id = pkt.id;

        forwardIncV(pkt,id);

        % Need MapUpdateH to first initialize RNODE
        if isempty(RNODE{id}),
          disp(sprintf('MapUpdateV: waiting for RNODE on robot %d', id));
          break;
        end

        gcsMapUpdateV(id, pkt);
        gmapAdd(id, RNODE{id}.n);

        %}
      otherwise
        
        disp('Unknown packet!');
      
      end

      if (gettime- tmap > 10.0),
        tmap = gettime;
        gmapRecalc;
      end

      if (gettime - tIpc > 1.0),
        tIpc = gettime;
        gcsMapIPCSendMap;

        gdispMap(GMAP.im, GMAP.x, GMAP.y);
        drawnow;
      end
      
    end
  end


function forwardPose(data,id)
global IPC_OUTPUT

if ~isempty(IPC_OUTPUT),
  guiMsg.update = data;
  guiMsg.id = id;
  IPC_OUTPUT.ipcAPI('publish','RPose',serialize(guiMsg));
end


function forwardIncH(update, id)
global IPC_OUTPUT

if ~isempty(IPC_OUTPUT),
  guiMsg.update = update;
  guiMsg.id = id;
  IPC_OUTPUT.ipcAPI('publish','IncH',serialize(guiMsg));
end


function forwardIncV(update,id)
global IPC_OUTPUT

if ~isempty(IPC_OUTPUT),
  guiMsg.update = update;
  guiMsg.id = id;
  IPC_OUTPUT.ipcAPI('publish','IncV',serialize(guiMsg));
end

function saveLog()
global GMAP GPOSE GTRANSFORM GDISP RPOSE RNODE RCLUSTER RCLUSTER_INFO IPC_OUTPUT
persistent lastSave

if isempty(lastSave)
  lastSave = gettime;
end

if (gettime - lastSave > 600)
  savefile = ['/tmp/gcs_map_', datestr(clock,30)];
  disp(sprintf('Saving map log file: %s', savefile));
  eval(['save ' savefile ' GMAP GPOSE GTRANSFORM GDISP RPOSE RNODE RCLUSTER RCLUSTER_INFO IPC_OUTPUT']);
  lastSave = gettime;
end


