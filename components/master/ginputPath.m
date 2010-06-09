function ginputPath(id)

global ROBOTS
global RPOSE

[xp, yp] = ginput;

msgName = ['Robot',num2str(id),'/Path'];

if ~isempty(xp),
  PATH = [RPOSE{id}.x RPOSE{id}.y; xp(:) yp(:)];
  ROBOTS(id).ipcAPI('publish', msgName, serialize(PATH));
end
