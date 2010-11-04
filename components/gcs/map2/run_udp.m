function run_udp

  more off

  % Load scenario parameters
  gcsParams;
  
  % Initialize global variables
  gcsMapInit;
  
  % Setup IPC output
  gcsMapIPCInit(true);
  
  global GMAP RNODE
  gdispInit;

  gcsLogPackets('entry');

  % Connect to UDP
  addr = '192.168.10.220';
  port = 12346;
  UdpReceiveAPI('connect', addr, port);

  tmap = clock;
  while 1,
    pause(.05);

    packets = UdpReceiveAPI('receive');
    gcsLogPackets('UDP', packets);
    n = length(packets);
    for ii = 1:n,
      try
        pkt = deserialize(zlibUncompress(packets(ii).data));
      catch
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
        gcsMapUpdateH(id, pkt);
        gcsMapFitPose(id);
 
        if (RNODE{id}.gpsInitialized),
          gdispRobot(id, RNODE{id}.pF(:,end));
        end
          
      case 'MapUpdateV'

        id = pkt.id;
        forwardIncV(pkt,id);
        gcsMapUpdateV(id, pkt);

        gmapAdd(id, RNODE{id}.n);

      otherwise
        
        disp('Unknown packet!');
      
      end

      if (etime(clock, tmap) > 1),
        gcsMapIPCSendMap;

        tmap = clock;
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


