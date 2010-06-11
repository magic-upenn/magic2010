function ginputTrack(id)

global ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(id),'/OoiDynamic'];

if ~isempty(xp),
  ooi = [xp(1) yp(1)];
  ROBOTS(id).ipcAPI('publish', msgName, serialize(ooi));
end
