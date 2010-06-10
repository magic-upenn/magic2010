function gcsUpdate

global RPOSE RMAP

% Non blocking receive:
masterReceiveFromRobots();
GetLocalMsg();
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



