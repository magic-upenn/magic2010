function gcsUAVFeed(event)
global UAV_FEED
persistent uavFid

switch event
case 'entry'
  uavIP = '64.9.88.210';
  uavPort = 6117;
  uavFid = tcpopen(uavIP, uavPort);
  UAV_FEED = [];
case 'update'
  UAV_FEED = uavParse(uavFid);
  UAVOverlay();
end

