function gcsUpdateIPC

global GCS
global RPOSE RMAP
global GPOSE GMAP GTRANSFORM
global EXPLORE_REGIONS AVOID_REGIONS OOI

% Non blocking receive:
masterReceiveFromRobots();

packets = UdpReceiveAPI('receive');
gcsLogPackets('UDP',packets);
n = length(packets);
if n > 0
    for ii=1:n
      fprintf(1,'got packet of size %d\n',length(packets(ii).data));
      packet = deserialize(zlibUncompress(packets(ii).data));
      if ~isfield(packet,'type'), continue, end
      if ~ischar(packet.type), continue, end

      switch(packet.type)
        case 'Pose'
          gcsRecvPoseExternal(serialize(packet),sprintf('Robot%d/PoseExternal',packet.id));
        case 'MapUpdateH'
          gcsRecvIncMapUpdateH(serialize(packet),sprintf('Robot%d/MapUpdateH',packet.id));
        case 'MapUpdateV'
          gcsRecvIncMapUpdateV(serialize(packet),sprintf('Robot%d/MapUpdateV',packet.id));
      end
    end
end

GetLocalMsg();

if (gettime - GCS.tSave > 60)
  savefile = ['/tmp/gcs_', datestr(clock,30)];
  disp(sprintf('Saving log file: %s', savefile));
  eval(['save ' savefile ' RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI ']);
  GCS.tSave = gettime;
end

end

function GetLocalMsg
global gcs_machine
global IPC
msgs = gcs_machine.ipcAPI('listen',50);
gcsLogPackets('LocalIPC',msgs);
nmsg = length(msgs);
%process messages
for mi=1:nmsg
    name = msgs(mi).name;
    name(name=='/')='_';
    if isfield(IPC.handler,name),
      IPC.handler.(name)(msgs(mi).data,msgs(mi).name);
    else
      warning('no handler for message name %s',msgs(mi).name);
    end
end
end



