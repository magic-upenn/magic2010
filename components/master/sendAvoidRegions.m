function sendAvoidRegions()
global GCS ROBOTS AVOID_REGIONS

if isempty(AVOID_REGIONS)
  msg.x = [];
  msg.y = [];
else
  msg.x = cell2mat({AVOID_REGIONS(:).x});
  msg.y = cell2mat({AVOID_REGIONS(:).y});
end
for id = GCS.ids
  msgName = ['Robot',num2str(id),'/Avoid_Regions'];
  ROBOTS(id).ipcAPI('publish', msgName, serialize(msg));
end

