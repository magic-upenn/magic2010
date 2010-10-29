function ginputPoint(id)

global ROBOTS HAVE_ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(id),'/Goal_Point'];

if ~isempty(xp) && HAVE_ROBOTS,
  PATH = [xp(1) yp(1)];
  ROBOTS(id).ipcAPI('publish', msgName, serialize(PATH));
end
