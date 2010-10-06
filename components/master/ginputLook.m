function ginputLook(id)

global ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(id),'/Look_Msg'];

if ~isempty(xp),
  %ooi = [xp(1) yp(1)];
  ooi.theta = atan2(yp(1),xp(1));
  ooi.type = 'look';
  ROBOTS(id).ipcAPI('publish', msgName, serialize(ooi));
end
