function gcsUpdateIPC

global GCS
global RPOSE RMAP
global GPOSE GMAP GTRANSFORM
global EXPLORE_REGIONS AVOID_REGIONS OOI
global ROBOT_PATH OOI_PATH NC_PATH
global MAGIC_CONSTANTS

% Non blocking receive:
masterReceiveFromRobots();

GetLocalMsg();

if (gettime - GCS.tSave > 60)
  savefile = ['/tmp/gcs_', datestr(clock,30)];
  disp(sprintf('Saving log file: %s', savefile));
  eval(['save ' savefile ' RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS']);
  %ROBOT_PATH OOI_PATH NC_PATH
  %ROBOT_PATH vector of structs with x and y field (each is a vector)
  %OOI_PATH same as ROBOT_PATH but with serial and shirt fields (along with x and y)
  %NC_PATH (same as ROBOT_PATH)
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



