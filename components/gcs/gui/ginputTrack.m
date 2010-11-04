function ginputTrack(id)

global ROBOTS HAVE_ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(id),'/Look_Msg'];

if ~isempty(xp) && HAVE_ROBOTS,
  %ooi = [xp(1) yp(1)];
  ooi.theta = atan2(yp(1),xp(1));
  ooi.distance = sqrt(xp(1)^2+yp(1)^2);
  ooi.type = 'track';
  try
    ROBOTS(id).ipcAPI('publish', msgName, serialize(ooi));
  catch
  end
end
