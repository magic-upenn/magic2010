function gcsUpdateIPC

global GCS
global RPOSE RMAP
global GPOSE GMAP GTRANSFORM

% Non blocking receive:
masterReceiveFromRobots();
GetLocalMsg();

if (gettime - GCS.tSave > 20)
  savefile = ['/tmp/gcs_', datestr(clock,30)];
  disp(sprintf('Saving log file: %s', savefile));
  eval(['save ' savefile ' RPOSE RMAP GPOSE GMAP GTRANSFORM ']);
  GCS.tSave = gettime;
end

end

function GetLocalMsg
global gcs_machine
msgs = gcs_machine.ipcAPI('listen',50);
nmsg = length(msgs);
%process messages
for mi=1:nmsg
    name = msgs(mi).name;
    name(name=='/')='_';
    GPTRAJHandler(msgs(mi).data,msgs(mi).name);
end
end



