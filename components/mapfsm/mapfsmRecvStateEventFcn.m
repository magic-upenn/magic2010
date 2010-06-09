function mapfsmRecvStateEventFcn(data, name)

global MP

if ~isempty(data)
  event = deserialize(data);
if isstr(event),
  disp(sprintf('StateEvent: %s',event));
  MP.sm = setEvent(MP.sm, deserialize(data));
end
end
