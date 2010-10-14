function sendAvoidRegions()
global GCS ROBOTS AVOID_REGIONS HAVE_ROBOTS

if isempty(AVOID_REGIONS)
  msg.x = [];
  msg.y = [];
else
  msg.x = cell2mat({AVOID_REGIONS(:).x});
  msg.y = cell2mat({AVOID_REGIONS(:).y});
end

if HAVE_ROBOTS
  for id = GCS.ids
    msgName = ['Robot',num2str(id),'/Avoid_Regions'];
    [msg.x msg.y] = gpos_to_rpos(id, msg.x, msg.y);
    ROBOTS(id).ipcAPI('publish', msgName, serialize(msg));
  end
end
