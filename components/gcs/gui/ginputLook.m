function ginputLook(id)

global ROBOTS RPOSE HAVE_ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(id),'/Look_Msg'];

if ~isempty(xp) && HAVE_ROBOTS,
  %ooi = [xp(1) yp(1)];
  ooi.theta = atan2(yp(1)-RPOSE{id}.y,xp(1)-RPOSE{id}.x);
  ooi.phi = 0;
  ooi.type = 'look';
  try
    ROBOTS(id).ipcAPI('publish', msgName, serialize(ooi));
  catch
  end
  disp('sent look message');
end
