function sendStateEvent(id, x)

global ROBOTS HAVE_ROBOTS

msgName = ['Robot',num2str(id),'/StateEvent'];

if ~isempty(x) && HAVE_ROBOTS,
  ROBOTS(id).ipcAPI('publish', msgName, serialize(x));
end
