function sendStateEvent(id, x)

global ROBOTS

msgName = ['Robot',num2str(id),'/StateEvent'];

if ~isempty(x),
  ROBOTS(id).ipcAPI('publish', msgName, serialize(x));
end
