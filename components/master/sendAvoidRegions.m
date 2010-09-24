function sendAvoidRegions()
global GDISPLAY GCS ROBOTS

if isempty(GDISPLAY.avoidRegions)
  msg.x = [];
  msg.y = [];
else
  msg.x = cell2mat({GDISPLAY.avoidRegions(:).x});
  msg.y = cell2mat({GDISPLAY.avoidRegions(:).y});
end
for id = GCS.ids
  msgName = ['Robot',num2str(id),'/Avoid_Regions'];
  ROBOTS(id).ipcAPI('publish', msgName, serialize(msg));
end

