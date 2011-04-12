function gcsUAVFeed()
more off;

uavIP = '192.168.10.9';
uavPort = 6117;
uavFid = tcpopen(uavIP, uavPort);

ipcAPI = str2func('ipcAPI');
ipcAPI('connect');
ipcAPI('define','UAV_Feed');

tUpdate = 1.0;

while 1,
  pause(tUpdate);
  packet = uavParse(uavFid);
  ipcAPI('publish','UAV_Feed',serialize(packet));
end

