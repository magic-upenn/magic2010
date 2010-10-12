more off;

uavIP = '64.9.88.210';
uavPort = 6117;

uavFid = tcpopen(uavIP, uavPort);

while 1,
  pause(0.1);
  msg = uavParse(uavFid);
end
