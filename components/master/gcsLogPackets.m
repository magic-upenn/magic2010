function gcsLogPackets(type, packets)
global LOG_PACKETS

LOG_SIZE = 1000;

if ~LOG_PACKETS.enabled
  return
end

switch type
case 'entry'
  LOG_PACKETS.UDP{LOG_SIZE} = [];
  LOG_PACKETS.timeUDP(LOG_SIZE) = 0;
  LOG_PACKETS.countUDP = 0;
  LOG_PACKETS.RobotIPC{LOG_SIZE} = [];
  LOG_PACKETS.timeRobotIPC(LOG_SIZE) = 0;
  LOG_PACKETS.countRobotIPC = 0;
  LOG_PACKETS.LocalIPC{LOG_SIZE} = [];
  LOG_PACKETS.timeLocalIPC(LOG_SIZE) = 0;
  LOG_PACKETS.countLocalIPC = 0;
case 'exit'
  writeLogToFile;
case 'UDP'
  addPackets('UDP','timeUDP','countUDP',packets);
case 'RobotIPC'
  addPackets('RobotIPC','timeRobotIPC','countRobotIPC',packets);
case 'LocalIPC'
  addPackets('LocalIPC','timeLocalIPC','countLocalIPC',packets);
end

function addPackets(list,timestamps,count,packets)
global LOG_PACKETS

n = length(packets);

if n==0
  return
end

%fprintf(1,'%s\n',list);
packet_idx = 0;
m = length(LOG_PACKETS.(list));
t = gettime;
while (n-packet_idx) + LOG_PACKETS.(count) >= m
  %finish filling and dump to file
  
  num = n - packet_idx;
  for i=1:num
    LOG_PACKETS.(list){LOG_PACKETS.(count)+i} = packets(packet_idx+i);
    LOG_PACKETS.(timestamps)(LOG_PACKETS.(count)+i) = t;
  end
  %LOG_PACKETS.(list)(LOG_PACKETS.(count)+1:end) = packets(packet_idx+1:packet_idx+m-LOG_PACKETS.(count));
  %LOG_PACKETS.(timestamps)(LOG_PACKETS.(count)+1:end) = t;

  packet_idx = packet_idx+m-LOG_PACKETS.(count);
  LOG_PACKETS.(count) = m;
  writeLogToFile;
end
if packet_idx < n
  %n
  %m
  %packet_idx
  %LOG_PACKETS.(count)+1
  %LOG_PACKETS.(count)+n-packet_idx
  %length(packets(packet_idx+1:end))

  num = n - packet_idx;
  for i=1:num
    LOG_PACKETS.(list){LOG_PACKETS.(count)+i} = packets(packet_idx+i);
    LOG_PACKETS.(timestamps)(LOG_PACKETS.(count)+i) = t;
  end
  %LOG_PACKETS.(list)(LOG_PACKETS.(count)+1:LOG_PACKETS.(count)+n-packet_idx) = packets(packet_idx+1:end);
  %LOG_PACKETS.(timestamps)(LOG_PACKETS.(count)+1:LOG_PACKETS.(count)+n-packet_idx) = t;

  LOG_PACKETS.(count) = LOG_PACKETS.(count)+n-packet_idx;
end

function writeLogToFile
global LOG_PACKETS

if LOG_PACKETS.countUDP > 0
  LOG.UDP = LOG_PACKETS.UDP(1:LOG_PACKETS.countUDP);
  LOG.timeUDP = LOG_PACKETS.timeUDP(1:LOG_PACKETS.countUDP);
else
  LOG.UDP = {};
  LOG.timeUDP = [];
end
if LOG_PACKETS.countRobotIPC > 0
  LOG.RobotIPC = LOG_PACKETS.RobotIPC(1:LOG_PACKETS.countRobotIPC);
  LOG.timeRobotIPC = LOG_PACKETS.timeRobotIPC(1:LOG_PACKETS.countRobotIPC);
else
  LOG.RobotIPC = {};
  LOG.timeRobotIPC = [];
end
if LOG_PACKETS.countLocalIPC > 0
  LOG.LocalIPC = LOG_PACKETS.LocalIPC(1:LOG_PACKETS.countLocalIPC);
  LOG.timeLocalIPC = LOG_PACKETS.timeLocalIPC(1:LOG_PACKETS.countLocalIPC);
else
  LOG.LocalIPC = {};
  LOG.timeLocalIPC = [];
end

savefile = ['/tmp/gcs_log_', datestr(clock,30)];
disp(sprintf('Saving UDP/IPC log file: %s', savefile));
eval(['save ' savefile ' LOG ']);

LOG_PACKETS.countUDP = 0;
LOG_PACKETS.countRobotIPC = 0;
LOG_PACKETS.countLocalIPC = 0;

