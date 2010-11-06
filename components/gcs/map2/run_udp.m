function run_udp

  more off

  global GMAP
  global GPOSE
  global RPOSE RNODE RCLUSTER

  % Load scenario parameters
  gcsParams;
  
  % Initialize global variables
  gcsMapInit;
  gdispInit;
  
  % Setup IPC output
  gcsMapIPCInit(true);

  gcsLogPackets('entry');

  % Connect to UDP
  addr = '192.168.10.220';
  port = 12346;
  UdpReceiveAPI('connect', addr, port);

  tmap = clock;
  tIpc = clock;

  while 1,
    pause(.02);

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
      case 'Pose'
      % Pose packet:

        id = pkt.id;
        forwardPose(pkt,id);
        gcsMapPoseExternal(id, pkt);

      case 'MapUpdateH'

        id = pkt.id;

	forwardIncH(pkt,id);
        %{
        % Need pose first for MapUpdateH
        if isempty(RPOSE{id}),
          disp('MapUpdateH: waiting for pose on robot %d', id);
          break;
        end
        %}

        gcsMapUpdateH(id, pkt);
        gcsMapFitPose(id);
 
        %gdispRobot(id, RNODE{id}.pF(:,end));
        gdispRobot(id, GPOSE{id});

          
      case 'MapUpdateV'

        id = pkt.id;

	forwardIncV(pkt,id);

        % Need MapUpdateH to first initialize RNODE
        %{
        if isempty(RNODE{id}),
          disp('MapUpdateV: waiting for RNODE on robot %d', id);
          break;
        end
        %}

        gcsMapUpdateV(id, pkt);
        gmapAdd(id, RNODE{id}.n);

      otherwise
        
        disp('Unknown packet!');
      
      end

      if (etime(clock, tmap) > 5.0),
        tmap = clock;
        gmapRecalc;
      end

      if (etime(clock, tIpc) > 1.0),
        tIpc = clock;
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
