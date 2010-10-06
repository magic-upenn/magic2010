function gcsUpdateIPC

global GCS
global RPOSE RMAP
global GPOSE GMAP GTRANSFORM
global EXPLORE_REGIONS AVOID_REGIONS OOI

% Non blocking receive:
masterReceiveFromRobots();
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



