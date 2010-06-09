function sendStateEvent(id, x)

global ROBOTS

msgName = ['Robot',num2str(id),'/StateEvent'];

if ~isempty(xp),
  ROBOTS(id).ipcAPI('publish', msgName, serialize(x));
end
